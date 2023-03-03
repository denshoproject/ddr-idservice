import logging
logger = logging.getLogger(__name__)

from django.conf import settings
from django.contrib.auth.models import User, Group
from django.http import HttpResponseRedirect

from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.reverse import reverse
from rest_framework.views import APIView

from . import models


@api_view(['GET'])
def index(request, format=None):
    """NOID Minter Index
    
    List and create Densho NOIDs.
    
    TEMPLATE - Form described in https://metacpan.org/dist/Noid/view/noid#TEMPLATES
    
    Swagger: /api/swagger/
    """
    data = {}
    for template in models.Noid.templates():
        data[template] = reverse(
            'nm-api-noids', args=[template], request=request, format=format,
        )
    return Response(data)


class Noids(APIView):

    def get(self, request, template, format=None):
        """Returns N most recent Noids for specified template
        
        limit (default 10)
        limit=all to get all records
        """
        naan = settings.NOIDMINTER_NAAN
        limit = int(request.GET.get('limit', '10'))
        noids = [
            noid.id
            for noid in models.Noid.objects \
                .filter(naan=naan, template=template).order_by('-n')[:limit]
        ]
        return Response(noids)

    def post(self, request, template, format=None):
        """Creates and returns the next N NOID(s) for the specified template
        
        limit (default 1) - Create specified number of new NOIDs
        
        USERNAME = 'REDACTED'     # idservice username
        PASSWORD = 'REDACTED'     # idservice password
        TEMPLATE = 'ddr.zeedeedk' # NOID format
        NUMBER_OF_IDS = 5
        import requests
        url = f'http://192.168.1.100:8082/noid/api/1.0/{TEMPLATE}/'
        r = requests.post(url, data={'num': NUMBER_OF_IDS}, auth=(USERNAME,PASSWORD))
        r.json()
        """
        num = int(request.POST.get('num', '1'))
        n = models.Noid.max_n(template)
        noids = []
        while(num):
            num = num - 1
            n = n + 1
            noid = models.Noid.mint(template, n)
            noid.save()
            noids.append(noid.id)
        return Response(noids)
