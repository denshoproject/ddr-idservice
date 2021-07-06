from django.urls import include, path

from drf_yasg import views as yasg_views
from drf_yasg import openapi
from rest_framework import permissions
from rest_framework.routers import DefaultRouter
from rest_framework.authtoken import views

from . import views
from noidminter import views as nm_views


router = DefaultRouter()
router.register(r'users', views.UserViewSet)
router.register(r'groups', views.GroupViewSet)
router.register(r'objectids', views.ObjectIDViewSet)
router.register(r'noids', nm_views.NoidViewSet)

schema_view = yasg_views.get_schema_view(
   openapi.Info(
      title="DDR ID Service API",
      default_version='0.1',
      #description="DESCRIPTION TEXT HERE",
      terms_of_service="http://ddr.densho.org/terms/",
      contact=openapi.Contact(email="info@densho.org"),
      #license=openapi.License(name="TBD"),
   ),
   #validators=['flex', 'ssv'],
   public=True,
   permission_classes=(permissions.AllowAny,),
)

urlpatterns = [

    path('api/swagger.json', schema_view.without_ui(cache_timeout=0), name='schema-json'),
    path('api/swagger.yaml', schema_view.without_ui(cache_timeout=0), name='schema-yaml'),
    path('api/swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('api/redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),

    path('api/0.1/objectids/<slug:oid>/next/<slug:model>/', views.next_object, name='next-object'),
    path('api/0.1/objectids/<slug:oid>/check/', views.check_ids, name='check-ids'),
    path('api/0.1/objectids/<slug:oid>/children/', views.object_children, name='object-children'),
    path('api/0.1/objectids/<slug:oid>/create/', views.create_ids, name='create-ids'),
    
    path('api/0.1/rest-auth/', include('rest_auth.urls')),
    path('api/0.1/auth/', include('rest_framework.urls', namespace='rest_framework')),
    path('api/0.1/', include(router.urls)),
    path('', views.index, name='index'),
]
