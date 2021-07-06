from rest_framework import serializers

from .models import Noid


class NoidSerializer(serializers.HyperlinkedModelSerializer):
    #group = serializers.ReadOnlyField(source='group.name')
    
    class Meta:
        model = Noid
        fields = (
            'id',
            'naan',
            'template',
            'n',
            'created',
            'modified',
        )
