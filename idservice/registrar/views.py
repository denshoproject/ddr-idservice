from django.contrib.auth.models import User, Group

from rest_framework import viewsets
from rest_framework.decorators import api_view
from rest_framework.reverse import reverse

from .models import ObjectID
from .serializers import UserSerializer, GroupSerializer, ObjectIDSerializer


@api_view(['GET'])
def api_root(request, format=None):
    return Response({
        'users': reverse('user-list', request=request, format=format),
        'groups': reverse('group-list', request=request, format=format),
        'objectids': reverse('objectid-list', request=request, format=format),
    })

class UserViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows users to be viewed or edited.
    """
    queryset = User.objects.all().order_by('-date_joined')
    serializer_class = UserSerializer

class GroupViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows groups to be viewed or edited.
    """
    queryset = Group.objects.all()
    serializer_class = GroupSerializer

class ObjectIDViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows ObjectID to be viewed or edited.
    """
    queryset = ObjectID.objects.all()
    serializer_class = ObjectIDSerializer
