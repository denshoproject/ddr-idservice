from rest_framework import permissions


class AuthenticatedAndGroupMember(permissions.IsAuthenticatedOrReadOnly):
    """Users can only manipulate objects belonging to their group(s).
    """
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return request.user.is_staff or obj.group in request.user.groups.all()
