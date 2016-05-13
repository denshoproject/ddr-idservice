from django.contrib.auth.models import User, Group

from rest_framework import serializers

from .models import ObjectID


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = (
            'id',
            'username',
            'email',
            'first_name',
            'last_name'
        )

class GroupSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Group
        fields = (
            'url',
            'name',
        )

class ObjectIDSerializer(serializers.HyperlinkedModelSerializer):
    group = serializers.ReadOnlyField(source='group.name')
    
    class Meta:
        model = ObjectID
        fields = (
            'url',
            'id',
            'model',
            'group',
        )
