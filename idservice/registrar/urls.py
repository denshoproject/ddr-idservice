from django.urls import include, path

from rest_framework.routers import DefaultRouter
from rest_framework.authtoken import views

from . import views


router = DefaultRouter()
router.register(r'users', views.UserViewSet)
router.register(r'groups', views.GroupViewSet)
router.register(r'objectids', views.ObjectIDViewSet)

urlpatterns = [

    path('api/0.1/objectids/<slug:oid>/next/<slug:model>/', views.next_object, name='next-object'),
    path('api/0.1/objectids/<slug:oid>/check/', views.check_ids, name='check-ids'),
    path('api/0.1/objectids/<slug:oid>/children/', views.object_children, name='object-children'),
    path('api/0.1/objectids/<slug:oid>/create/', views.create_ids, name='create-ids'),
    
    path('api/0.1/rest-auth/', include('rest_auth.urls')),
    path('api/0.1/auth/', include('rest_framework.urls', namespace='rest_framework')),
    path('api/0.1/', include(router.urls)),
    path('', views.index, name='index'),
]
