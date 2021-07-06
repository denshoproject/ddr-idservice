import logging
logger = logging.getLogger(__name__)

from django.contrib.auth.models import User, Group
from django.http import HttpResponseRedirect

from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.reverse import reverse
from rest_framework.views import APIView

from . import models


@api_view(['GET'])
def index(request, format=None):
    """Swagger UI: /api/swagger/
    """
    data = {
        #'noids': reverse('nm-api-noids', request=request),
    }
    return Response(data)


class Noids(APIView):

    def get(self, request, naan, template, format=None):
        """Returns ?limit=N most recent Noids for specified NAAN and template
        
        limit (default 10)
        limit=all to get all records
        """
        limit = int(request.GET.get('limit', '10'))
        noids = [
            noid.id
            for noid in models.Noid.objects \
                .filter(naan=naan, template=template).order_by('-n')[:limit]
        ]
        return Response(noids)

    def post(self, request, naan, template, format=None):
        """Get the next NOID for the specified NAAN and template
        """
        num = int(request.POST.get('num', '1'))
        n = models.Noid.max_n(naan, template)
        noids = []
        while(num):
            num = num - 1
            n = n + 1
            noid = models.Noid.mint(naan, template, n)
            noid.save()
            noids.append(noid.id)
        return Response(noids)
