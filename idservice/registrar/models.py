from __future__ import unicode_literals
from datetime import datetime
import json
import logging
logger = logging.getLogger(__name__)

from django.conf import settings
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth.models import Group
from django.core.urlresolvers import reverse
from django.db import models

from rest_framework.authtoken.models import Token
from rest_framework.reverse import reverse

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
        try:
            return identifier.Identifier(id=self.id)._key()
        except:
            return self.id
    
    def __lt__(self, other):
        """Enables Pythonic sorting; see Identifier._key.
        """
        return self._key() < other._key()

    def dict(self):
        return {
            'id': self.id,
            'model': self.model,
            'group': self.group.name,
            'url': self.absolute_url(),
        }
    
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
    
    @staticmethod
    def children(i):
        """Gets children of ObjectID
        
        @param i: Identifier
        @returns: list of ObjectIds
        """
        return sorted(ObjectID.objects.filter(
            group=Group.objects.get(name=i.parts['org']),
            id__contains='%s-' % i.id,
        ))
    
    @staticmethod
    def loads(objectids):
        """Takes data from .json file and generates list of ObjectIDs
        
        Used by registrar.idimport management command.
        See ddr-cmdln/ddr/bin/ddr-idexport.
        
        >>> data = [
        ...     'ddr-test-123',
        ...     'ddr-test-123-1',
        ...     'ddr-test-123-1-role-abc123',
        ...     ...
        ... ]
        >>> with open('/tmp/ddr-test-123.json', 'w') as f:
        >>>     f.write(json.dumps(data))
        $ python manage.py idimport /tmp/ddr-test-123.json
        
        @param: list of str IDs
        @generates: list of ObjectIDs
        """
        groups = {
            group.name: group
            for group in Group.objects.all()
        }
        for n,oid in enumerate(objectids):
            i = identifier.Identifier(oid)
            try:
                o = ObjectID.objects.get(id=i.id)
                new = 'EXST'
            except:
                o = ObjectID(
                    id=i.id,
                    model=i.model,
                    group=groups[i.parts['org']],
                    created=datetime.now(),
                    modified=datetime.now(),
                )
                new = 'NEU!'
            o.save()
            o.new = new
            yield o
    
    def collection(self):
        """
        @returns: identifier
        """
        return self.identifier().collection()
    
    def identifier(self):
        return identifier.Identifier(self.id)
    
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
            # Append separator to collection ID
            query_cid = '%s-' % cidentifier.id
            # Without this the query pulls in IDs from other collections
            # Ex: asking for 'ddr-abc-12' will also get 'ddr-abc-129'.
            identifiers = [
                identifier.Identifier(o.id)
                for o in ObjectID.objects.filter(
                    id__contains=query_cid,
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
        
        if identifiers == []:
            # create first of series
            first = identifier.first_id(oi, model)
            return ObjectID.get(first)
        
        elif identifiers:
            identifiers.sort()
            last = identifiers[-1]
            return ObjectID.get(last.next())
        
        return None
    
    def check_ids(self, object_ids):
        """Given list of EIDs, indicates which are registered,unregistered.
        
        @param requested_ids: list of object ID strings
        @returns: 
        """
        logging.debug('check_ids(%s)' % (self))
        collection_id = self.collection().id
        logging.debug('collection_id: %s' % collection_id)
        existing_ids = [
            o.id
            for o in ObjectID.objects.filter(
                group=self.group,
                id__startswith=collection_id,
            )
        ]
        data = {
            'registered': [],
            'unregistered': [],
        }
        for oid in object_ids:
            if oid in existing_ids:
                logging.debug('| existing %s' % oid)
                data['registered'].append(oid)
            else:
                logging.debug('|      NEW %s' % oid)
                data['unregistered'].append(oid)
        logging.debug('DONE')
        return data
    
    def create_ids(self, requested_ids):
        """Create ObjectIDs for the requested_ids.
        
        @param requested_ids: list of object ID strings
        @returns: list ObjectID.id strs
        """
        logging.debug('create_ids()')
        data = {
            'created': [],
        }
        for oid in requested_ids:
            logging.debug('| creating %s' % oid)
            o = ObjectID.get(identifier.Identifier(oid))
            o.save()
            data['created'].append(o.id)
        logging.debug('DONE')
        return data
