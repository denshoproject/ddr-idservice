import json

from django.contrib.auth.models import Group
from django.core.management.base import BaseCommand

from DDR import identifier
from registrar.models import ObjectID


class Command(BaseCommand):
    """See helptext for registrar.models.ObjectID.loads
    """
    help = 'Import list of IDs from .json and create ObjectIDs.  ' \
           'See ddr-idservice:registrar.models.loads ' \
           'and ddr-cmdln:ddr-idexport.'

    def add_arguments(self, parser):
        parser.add_argument('path', nargs='*', type=str)

    def handle(self, *args, **options):
        path = options['path'][0]
        self.stdout.write('Reading from %s' % path)
        
        with open(path, 'r') as f:
            objectids = json.loads(f.read())

        num = len(objectids)
        self.stdout.write('%s items' % num)
        for n,objectid in enumerate(ObjectID.loads(objectids)):
            self.stdout.write('%s/%s %s %s' % (n, num, objectid.new, objectid))
