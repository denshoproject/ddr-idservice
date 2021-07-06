from datetime import datetime
import logging
logger = logging.getLogger(__name__)

from django.conf import settings
from django.db import models

from rest_framework.reverse import reverse

from . import pynoid


class Noid(models.Model):
    id = models.CharField(max_length=32, primary_key=True)
    n = models.IntegerField()
    naa = models.CharField(max_length=32)
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
            'naa': self.naa,
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
    def max_n(naa, template):
        try:
            max = Noid.objects.filter(naa=naa, template=template).latest('n')
        except Noid.DoesNotExist:
            return 0
        return max.n

    @staticmethod
    def mint(naa, template, n):
        noid = Noid(
            id=pynoid.mint(naa=naa, template=template, n=n),
            n=n,
            naa=naa,
            template=template,
            created=datetime.now(),
            modified=datetime.now(),
        )
        return noid
