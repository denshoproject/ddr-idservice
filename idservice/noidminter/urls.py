from django.urls import include, path, re_path

from . import api

urlpatterns = [
    
    #path('api/1.0/<slug:thing>/', api.thing, name='nm-api-thing'),
    #re_path(r"^api/1.0/noids/(?P<thing>[\w\W]+)/$", api.something, name='nm-api-something'),

    #path('api/1.0/ark/<slug:naan>/<slug:template>/', api.Ark.as_view(), name='nm-api-ark'),
    re_path(r"^api/1.0/(?P<naan>[\w\W]+)/(?P<template>[\w\W.]+)/$", api.Ark.as_view(), name='nm-api-ark'),

    path('api/1.0/', api.index, name='nm-api-index'),
    path('api/', api.index, name='nm-api-index'),
]
