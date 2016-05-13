import json

from django.contrib.auth.models import Group
from django.core.management.base import BaseCommand

from DDR import identifier
from registrar import models


class Command(BaseCommand):
    help = 'Import list of IDs from .json and create ObjectIDs.'

    def add_arguments(self, parser):
        parser.add_argument('path', nargs='*', type=str)

    def handle(self, *args, **options):
        path = options['path'][0]
        self.stdout.write('Reading from %s' % path)
        
        with open(path, 'r') as f:
            objectids = json.loads(f.read())
        
        groups = {
            group.name: group
            for group in Group.objects.all()
        }
        num = len(objectids)
        self.stdout.write('%s items' % num)
        for n,oid in enumerate(objectids):
            i = identifier.Identifier(oid)
            try:
                o = models.ObjectID.objects.get(id=i.id)
                new = 'EXST'
            except:
                o = models.ObjectID(
                    id=i.id,
                    model=i.model,
                    group=groups[i.parts['org']],
                )
                new = 'NEU!'
            o.save()
            self.stdout.write('%s/%s %s %s' % (n, num, new, o))
