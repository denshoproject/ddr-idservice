from __future__ import unicode_literals

from django.contrib.auth.models import Group
from django.core.urlresolvers import reverse
from django.db import models

from DDR import identifier


class ObjectID(models.Model):
    id = models.CharField('object ID', max_length=255, primary_key=True)
    group = models.ForeignKey(Group)
    collection_id = models.CharField('collection ID', max_length=255)
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
        return self.id
