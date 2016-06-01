from django.contrib import admin

from .models import ObjectID


@admin.register(ObjectID)
class ObjectIDAdmin(admin.ModelAdmin):
    fields = ('group', 'id', 'model',)
    list_display = ('id', 'group', 'model',)
    list_filter = ('group', 'model')
    search_fields = ['id']
