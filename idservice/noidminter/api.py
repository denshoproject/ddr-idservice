import logging
logger = logging.getLogger(__name__)

from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework.reverse import reverse
from rest_framework.views import APIView


@api_view(['GET'])
def index(request, format=None):
    """Swagger UI: /api/swagger/
    """
    data = {
        #'noids': reverse('nm-api-noids', request=request),
    }
    return Response(data)
