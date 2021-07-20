from datetime import datetime
import logging
logger = logging.getLogger(__name__)

from django.conf import settings
from django.db import models, connection

from rest_framework.reverse import reverse

from . import pynoid


class Noid(models.Model):
    id = models.CharField(max_length=32, primary_key=True)
    n = models.IntegerField()
    naan = models.CharField(max_length=32)
    template = models.CharField(max_length=32)
    created = models.DateTimeField(auto_now_add=True)
    modified = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['id',]

    def __repr__(self):
        return "<%s.%s %s (%s)>" % (
            self.__module__, self.__class__.__name__, self.id, self.n
        )

    def __unicode__(self):
        return self.__repr__()

    #def absolute_url(self):
    #    return reverse('objectid-detail', args=[self.id])

    def __lt__(self, other):
        """Enables Pythonic sorting; see Identifier._key.
        """
        return self.id < other.id

    def dict(self):
        return {
            'id': self.id,
            'naan': self.naan,
            'template': self.template,
            'n': self.n,
            'created': self.created,
            'modified': self.modified,
            #'url': self.absolute_url(),
        }

    @staticmethod
    def exists(noid):
        """See if NOID exists in database
        """
        try:
            noid = models.Noid.objects.get(noid)
        except Noid.DoesNotExist:
            return False
        return True

    @staticmethod
    def max_n(template):
        try:
            max = Noid.objects.filter(
                naan=settings.NOIDMINTER_NAAN, template=template
            ).latest('n')
        except Noid.DoesNotExist:
            return 0
        return max.n

    @staticmethod
    def mint(template, n):
        noid = Noid(
            id=pynoid.mint(naa=settings.NOIDMINTER_NAAN, template=template, n=n),
            n=n,
            naan=settings.NOIDMINTER_NAAN,
            template=template,
            created=datetime.now(),
            modified=datetime.now(),
        )
        return noid

    @staticmethod
    def templates():
        q = f'SELECT DISTINCT template FROM noidminter_noid WHERE naan={settings.NOIDMINTER_NAAN};'
        with connection.cursor() as cursor:
            cursor.execute(q)
            templates = [row[0] for row in cursor.fetchall()]
        return templates
