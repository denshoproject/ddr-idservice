from django.contrib import admin

from .models import ObjectID


@admin.register(ObjectID)
class ObjectIDAdmin(admin.ModelAdmin):
    fields = (
        'group',
        'id',
        'model',
        'created',
        'modified',
    )
    readonly_fields = ('created', 'modified',)
    list_display = ('id', 'group', 'model', 'created',)
    list_filter = ('group', 'model', 'created',)
    search_fields = ['id']
