from django.contrib.auth.models import User, Group

from rest_framework import serializers

from .models import ObjectID


class UserSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = User
        fields = ('url', 'username', 'email', 'groups')

class GroupSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Group
        fields = ('url', 'name')

class ObjectIDSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = ObjectID
        fields = ('url', 'id', 'collection_id', 'model', 'group')
