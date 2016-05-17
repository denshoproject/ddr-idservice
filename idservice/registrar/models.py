from __future__ import unicode_literals
import json

from django.conf import settings
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth.models import Group
from django.core.urlresolvers import reverse
from django.db import models

from rest_framework.authtoken.models import Token

from DDR import identifier


@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def create_auth_token(sender, instance=None, created=False, **kwargs):
    """Catch User post_save signal and generate authentication token.
    """
    if created:
        Token.objects.create(user=instance)


class ObjectID(models.Model):
    id = models.CharField('object ID', max_length=255, primary_key=True)
    group = models.ForeignKey(Group, related_name='objectids')
    model = models.CharField('model', max_length=255)
    created = models.DateTimeField(auto_now_add=True)
    modified = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['id',]
    
    def __repr__(self):
        return "<%s.%s %s:%s>" % (
            self.__module__, self.__class__.__name__, self.model, self.id
        )
    
    def __unicode__(self):
        return self.__repr__()
    
    def absolute_url(self):
        return reverse('objectid-detail', args=[self.id])

    def _key(self):
        """Key for Pythonic object sorting.
        """
        return identifier.Identifier(self.id)._key()
    
    def __lt__(self, other):
        """Enables Pythonic sorting; see Identifier._key.
        """
        return self._key() < other._key()
    
    @staticmethod
    def get(i):
        """Gets ObjectID corresponding to Identifier.
        
        @param i: Identifier
        @returns: ObjectId
        """
        group = Group.objects.get(name=i.parts['org'])
        return ObjectID(
            id=i.id,
            group=group,
            model=i.model,
        )
    
    def identifiers(self, model):
        return _identifiers(self, model)
    
    @staticmethod
    def next(oi, model):
        """Gets next ObjectID for model,identifier
        
        NOTE: This has to be able to get new collection IDS,
        in which case we need to get the Group (organization)
        and then find collection ID for that.
	
        @param oi: Identifier
        @param model: str
        @returns: ObjectId
        """
        try:
            cidentifier = oi.collection()
        except Exception:
            cidentifier = None
        
        if cidentifier:
            identifiers = [
                identifier.Identifier(o.id)
                for o in ObjectID.objects.filter(
                    id__contains=cidentifier.id,
                    model=model
                )
            ]
        else:
            identifiers = [
                identifier.Identifier(o.id)
                for o in ObjectID.objects.filter(
                    group=Group.objects.get(name=oi.parts['org']),
                    model=model
                )
            ]
        
        if identifiers:
            identifiers.sort()
            last = identifiers[-1]
            return ObjectID.get(last.next())
        return None
    
    @staticmethod
    def available(num_new, model, collection_id, startwith=None):
        """DESCRIPTION GOES HERE
        
        @param num_new: int
        @param model: str
        @param collection_id: str
        @param startwith: (optional) int
        @returns: 
        """
        identifiers = _identifiers(collection_id, model)
        result = identifier.available(
            num_new, model, identifiers, startwith
        )
        print('result %s' % result)
        
        # replace component IDs with Identifiers
        ci = identifier.Identifier(collection_id)
        partsd = {'model': self.model}
        for k,v in ci.parts.iteritems():
            partsd[k] = v
        print('partsd %s' % partsd)
        #taken
        #new
        #max_id

        def mkid(parts, k, v):
            parts[k] = v
            return identifier.Identifier(parts=parts)
        
        result['max'] = mkid(parts, k, v)
        print('result %s' % result)

def loads(data):
    """Takes data from .json file and returns ObjectIDs
    
    data = [
        {'collection_id': 'ddr-test-123', 'model': 'collection', 'id': 'ddr-test-123'},
        {'collection_id': 'ddr-test-123', 'model': 'entity', 'id': 'ddr-test-123-1'},
        {'collection_id': 'ddr-test-123', 'model': 'entity', 'id': 'ddr-test-123-2'},
        {'collection_id': 'ddr-test-123', 'model': 'file', 'id': 'ddr-test-123-1-role-abc123'},
        {'collection_id': 'ddr-test-123', 'model': 'file', 'id': 'ddr-test-123-2-role-abc123'},
        ...
    ]
    
    @param: list of dicts {'id', 'model', 'collection_id'}
    @returns: list of ObjectIDs
    """
    groups = {}
    for d in data:
        cid = d['collection_id']
        if not groups.get(cid):
            i = identifier.Identifier(cid)
            groups[cid] = Group.objects.get(name=i.parts['org'])
    oids = [
        ObjectID(
            id=d['id'],
            group=groups[d['collection_id']],
            collection_id=d['collection_id'],
            model=d['model'],
        )
        for d in data
    ]
    oids.sort()
    return oids

def ingest(collection_path, dryrun=False):
    """Import all the IDs from a collection
    
    >>> from registrar import models
    >>> models.ingest('/var/www/media/ddr/ddr-testing-312')
    
    @param collection_path: str path to collection repo
    @param dryrun: boolean Don't save just print
    """
    ci = identifier.Identifier(collection_path)
    collection = ci.object()
    print(ci)
    print(collection)
    groups = {
        group.name: group
        for group in Group.objects.all()
    }
    cidentifiers = collection.identifiers()
    num = len(cidentifiers)
    for n,i in enumerate(cidentifiers):
        try:
            o = ObjectID.objects.get(id=i.id)
            new = 'EXST'
        except:
            o = ObjectID(
                id=i.id,
                group=groups[i.parts['org']],
            )
            new = 'NEU!'
        print('%s/%s %s %s' % (n, num, new, o))
        if not dryrun:
            o.save()
