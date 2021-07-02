from django.urls import include, path, re_path

from . import api

urlpatterns = [
    path('api/1.0/', api.index, name='nm-api-index'),
    path('api/', api.index, name='nm-api-index'),
]
