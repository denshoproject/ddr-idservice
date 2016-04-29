from django.contrib.auth.models import Group

from rest_framework import serializers

from .models import ObjectID


class GroupSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = Group
        fields = ('url', 'name')

class ObjectIDSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = ObjectID
        fields = ('url', 'id', 'collection_id', 'model', 'group')
