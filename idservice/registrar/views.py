import logging
logger = logging.getLogger(__name__)

from django.contrib.auth.models import User, Group
from django.http import HttpResponseRedirect
from django.urls import reverse

from rest_framework import permissions
from rest_framework import status
from rest_framework import viewsets
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.reverse import reverse

from .models import ObjectID
from .permissions import AuthenticatedAndGroupMember
from .serializers import UserSerializer, GroupSerializer, ObjectIDSerializer

from DDR import identifier


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


class UserViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows users to be viewed or edited.
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = (
        permissions.IsAdminUser,
    )


class GroupViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows groups to be viewed or edited.
    """
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    permission_classes = (
        permissions.IsAuthenticatedOrReadOnly,
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

@api_view(['GET'])
def object_children(request, oid):
    """List all the object's child IDs
    """
    data = [
        o.dict()
        for o in ObjectID.children(identifier.Identifier(oid))
    ]
    logger.debug('200')
    return Response(data, status=status.HTTP_200_OK)

@api_view(['GET', 'POST'])
def next_object(request, oid, model):
    logger.debug('%s next_object(%s, %s)' % (request.method, oid, model))
    oi = identifier.Identifier(oid)
    
    if model not in oi.child_models(stubs=True):
        reason = '400 %s not in child_models(%s)' % (
            model, oi.child_models(stubs=True)
        )
        logger.debug(reason)
        return Response(
            status=status.HTTP_400_BAD_REQUEST,
            data={'reason': reason},
        )
    
    if not identifier.Identifier.nextable(model):
        reason = '400 Identifier not nextable'
        logger.debug(reason)
        return Response(
            status=status.HTTP_400_BAD_REQUEST,
            data={'reason': reason},
        )
    
    next_object = ObjectID.next(oi, model)
    
    serializer = ObjectIDSerializer(
        data={
            'url': next_object.absolute_url(),
            'id': next_object.id,
            'model': next_object.model,
            'group': next_object.group,
        },
        context={'request': request}
    )
    if not serializer.is_valid():
        logger.debug('400 Invalid serializer %s' % serializer)
        return Response(status=status.HTTP_400_BAD_REQUEST)
    
    data = {
        'url': next_object.absolute_url(),
        'id': next_object.id,
        'model': next_object.model,
        'group': next_object.group.name,
    }
    
    if request.method == 'GET':
        #return Response(serializer.data, status=status.HTTP_200_OK)
        logger.debug('200 %s' % data['id'])
        return Response(data, status=status.HTTP_200_OK)
    
    elif request.method == 'POST':
        if not request.user.is_authenticated:
            logger.debug('403 User not authenticated')
            return Response(status=status.HTTP_403_FORBIDDEN)
        
        if not (
            request.user.is_staff or (next_object.group in request.user.groups.all())
        ):
            logger.debug('401 User not authorized')
            return Response(status=status.HTTP_401_UNAUTHORIZED)
        
        next_object.save()
        #return Response(serializer.data, status=status.HTTP_201_CREATED)
        logger.debug('201 %s (saved)' % data['id'])
        return Response(data, status=status.HTTP_201_CREATED)

@api_view(['POST'])
def check_ids(request, oid):
    """Given list of EIDs, indicates which are registered,unregistered.
    
    @param oid: str object ID string
    @returns: dict {'registered': list, 'unregistered': list}
    """
    logger.debug('check_ids(%s, %s)' % (request, oid))
    collectionid = ObjectID.get(identifier.Identifier(oid))
    object_ids = request.data.getlist('object_ids')
    if not object_ids:
        return Response(status=status.HTTP_400_BAD_REQUEST)
    data = collectionid.check_ids(object_ids)
    return Response(data, status=status.HTTP_200_OK)

@api_view(['POST'])
def create_ids(request, oid):
    """Create the specified entity IDs
    """
    logger.debug('create_ids(%s, %s)' % (request, oid))
    collectionid = ObjectID.get(identifier.Identifier(oid))
    object_ids = request.data.getlist('object_ids')
    if not object_ids:
        return Response(status=status.HTTP_400_BAD_REQUEST)
    data = collectionid.create_ids(object_ids)
    return Response(data, status=status.HTTP_201_CREATED)
