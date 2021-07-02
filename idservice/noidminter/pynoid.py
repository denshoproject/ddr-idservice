import random

DIGIT = '0123456789'
XDIGIT = DIGIT + 'bcdfghjkmnpqrstvwxz'
GENTYPES = 'rsz'
DIGTYPES = 'de'


def mint(scheme=None, naa=None, template='zek', n=None):
    """Mint identifiers according to template with a prefix of scheme + naa.

    Template is of form [mask] or [prefix].[mask] where prefix is any
    URI-safe string and mask is a string of any combination 'e' and 'd',
    optionally beginning with a mint order indicator ('r'|'s'|'z') and/or
    ending with a checkdigit ('k').
    See Noid on CPAN: https://metacpan.org/dist/Noid/view/noid#TEMPLATES

    'z' indicates that a namespace should expand on its first element to
    accommodate any 'n' value (eg. 'de' becomes 'dde' then 'ddde' as numbers
    get larger). That expansion can be handled by this method.

    'r' 'random' recognized as valid value but ignored and not implemented
    's' 'sequential' recognized as valid value but ignored and not implemented

    Example Templates:
    d      : 0, 1, 2, 3
    zek    : 00, xt, 3f0, 338bh
    123.zek: 123.00, 123.xt, 123.3f0, 123.338bh
    seddee : 00000, k50gh, 637qg
    seddeek: 000000, k06178, b661qj

    The result is appended to the scheme and naa as follows:
        f'{scheme}{naa}/{noid}'

    >>> pynoid.mint(scheme='ark:/', naa='88922', template='ddr.zek', n=10001)
    'ark:/88922/ddrcvv1'

    Minting is random within the namespace if no 'n' is given.  There is no
    checking to ensure ids are not reminted.

    """

    if '.' in template:
        prefix, mask = template.rsplit('.', 1)
    else:
        mask = template
        prefix = ''

    try:
        _validate_mask(mask)
    except InvalidTemplateError:
        raise

    if n is None:
        if mask[0] in GENTYPES:
            mask = mask[1:]
        n = random.randint(0, _get_total(mask) - 1)

    noid = prefix + _n2xdig(n, mask)
    if naa:
        noid = naa.strip('/') + '/' + noid
    if template[-1] == 'k':
        noid += _checkdigit(noid)
    if scheme:
        noid = scheme + noid

    return noid

def validate(s):
    """Checks if the final character is a valid checkdigit for the id. Will
    fail for ids with no checkdigit.

    This will also attempt to strip scheme strings (eg. 'doi:', 'ark:/') from
    the beginning of the string. This feature is limited, however, so if you
    haven't tested with your particular namespace, it's best to pass in ids
    with that data removed.

    Returns True on success, ValidationError on failure.
    """
    if not _checkdigit(s[0:-1]) == s[-1]:
        raise ValidationError(
            f"Noid check character '{s[-1]}' doesn't match up for '{s}'."
        )
    return True

def _n2xdig(n, mask):
    req = n
    xdig = ''
    for c in mask[::-1]:
        if c == 'e':
            div = len(XDIGIT)
        elif c == 'd':
            div = len(DIGIT)
        else:
            continue
        value = n % div
        n = n // div
        xdig += (XDIGIT[value])

    if mask[0] == 'z':
        c = mask[1]
        while n > 0:
            if c == 'e':
                div = len(XDIGIT)
            elif c == 'd':
                div = len(DIGIT)
            else:
                raise InvalidTemplateError(
                    f"Template mask is corrupt. Cannot process character: {c}"
                )
            value = n % div
            n = n // div
            xdig += (XDIGIT[value])

    # if there is still something left over, we've exceeded our namespace. 
    # checks elsewhere should prevent this case from ever evaluating true.
    if n > 0:
        raise NamespaceError(
            f"Cannot mint a noid for (counter = {str(req)}) within this namespace."
        )

    return xdig[::-1]

def _validate_mask(mask):
    masks = 'ed'
    checkchar = 'k'

    if not (mask[0] in GENTYPES or mask[0] in masks):
        raise InvalidTemplateError("Template is invalid.")
    elif not (mask[-1] in checkchar or mask[-1] in masks):
        raise InvalidTemplateError("Template is invalid.")
    else:
        for maskchar in mask[1:-1]:
            if not (maskchar in masks):
                raise InvalidTemplateError("Template is invalid.")

    return True

def _get_total(mask):
    if mask[0] == 'z':
        total = NOLIMIT
    else:
        total = 1
        for c in mask:
            if c == 'e':
                total *= len(XDIGIT)
            elif c == 'd':
                total *= len(DIGIT)
    return total

def _checkdigit(s):
    # TODO: Fix checkdigit to autostrip scheme names shorter or longer than 3
    #  chars.
    try:
        if s[3] == ':':
            s = s[4:].lstrip('/')
    except IndexError:
        pass

    def ordinal(x):
        try:
            return XDIGIT.index(x)
        except ValueError:
            return 0

    return XDIGIT[
        sum([x * (i + 1) for i, x in enumerate(map(ordinal, s))]) % len(XDIGIT)]


class InvalidTemplateError(Exception):
    pass


class ValidationError(Exception):
    pass


class NamespaceError(Exception):
    pass
