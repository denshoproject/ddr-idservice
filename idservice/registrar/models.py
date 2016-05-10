from __future__ import unicode_literals
import json

from django.contrib.auth.models import Group
from django.core.urlresolvers import reverse
from django.db import models

from DDR import identifier


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
        return self.id
    
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
        
        @param oi: Identifier
        @param model: str
        @returns: ObjectId
        """
        try:
            cidentifier = oi.collection()
        except Exception:
            cidentifier = None
        group = Group.objects.get(name=oi.parts['org'])
        
        if cidentifier:
            identifiers = _identifiers(cidentifier, model)
        elif group:
            identifiers = _identifiers_group(group, model)
        else:
            identifiers = []
        
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


def _identifiers(object_id, model=None):
    cid = identifier.Identifier(object_id.id).collection_id()
    group = object_id.group
    if cid and model:
        return [
            identifier.Identifier(o.id)
            for o in ObjectID.objects.filter(id__contains=cid, model=model)
        ]
    elif group and model:
        return [
            identifier.Identifier(o.id)
            for o in ObjectID.objects.filter(group=group, model=model)
        ]
    return None

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
