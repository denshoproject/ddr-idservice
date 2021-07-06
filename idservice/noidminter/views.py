import logging
logger = logging.getLogger(__name__)

from rest_framework import viewsets

from .models import Noid
from .permissions import AuthenticatedAndGroupMember
from .serializers import NoidSerializer


class NoidViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows ObjectID to be viewed or edited.
    """
    queryset = Noid.objects.all()
    serializer_class = NoidSerializer
    permission_classes = (
        AuthenticatedAndGroupMember,
    )
