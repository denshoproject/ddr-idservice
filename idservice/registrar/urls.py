from django.conf.urls import include, url

from rest_framework.routers import DefaultRouter

from . import views


router = DefaultRouter()
router.register(r'users', views.UserViewSet)
router.register(r'groups', views.GroupViewSet)
router.register(r'objectids', views.ObjectIDViewSet)

urlpatterns = [
    url(r'^api/0.1/', include(router.urls)),
    url(r'^api/0.1/auth/', include('rest_framework.urls', namespace='rest_framework')),
]
