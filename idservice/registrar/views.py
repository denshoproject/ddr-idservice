from django.contrib.auth.models import Group
from django.core.urlresolvers import reverse
from django.http import HttpResponseRedirect

from rest_framework import permissions
from rest_framework import viewsets
from rest_framework.decorators import api_view
from rest_framework.reverse import reverse

from .models import ObjectID
from .permissions import AuthenticatedAndGroupMember
from .serializers import GroupSerializer, ObjectIDSerializer


@api_view(['GET'])
def index(request):
    url = reverse('api-root')
    url = '/api/0.1/'
    return HttpResponseRedirect(url)

@api_view(['GET'])
def api_root(request, format=None):
    return Response({
        'groups': reverse('group-list', request=request, format=format),
        'objectids': reverse('objectid-list', request=request, format=format),
    })


class GroupViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows groups to be viewed or edited.
    """
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = (
        permissions.IsAdminUser,
    )


class ObjectIDViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows ObjectID to be viewed or edited.
    """
    queryset = ObjectID.objects.all()
    serializer_class = ObjectIDSerializer
    permission_classes = (
        AuthenticatedAndGroupMember,
    )
