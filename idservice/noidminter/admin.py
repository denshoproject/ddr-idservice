from django.contrib import admin

from .models import Noid


@admin.register(Noid)
class ObjectIDAdmin(admin.ModelAdmin):
    fields = (
        'id',
        'naan',
        'template',
        'created',
        'modified',
    )
    readonly_fields = ('template', 'naan', 'id', 'n', 'created', 'modified',)
    list_display = ('id', 'naan', 'template', 'created', 'modified',)
    list_filter = ('template', 'naan', 'created', 'modified',)
    search_fields = ['id']
