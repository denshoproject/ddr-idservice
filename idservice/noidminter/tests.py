import pytest

from django.test import Client, TestCase
from django.urls import reverse

from . import models

TEMPLATE = 'ddr.zeedeedk'
TEST_NOID = '88922/nr004n84j'


class AdminView(TestCase):

    def test_admin_index(self):
        url = '/admin/noidminter/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)

    def test_admin_index(self):
        url = '/admin/noidminter/noid/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)

class APIIndexView(TestCase):

    def test_index(self):
        url = '/api/0.1/noids/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)



#def post(client):
#    """see namesdb-editor::names.noidminter.get_noids"""
#    url = f'/noid/api/1.0/{TEMPLATE}/'
#    print(f'{url=}')
#    response = client.post(url)
#    print(f'{response=}')
#    print(f'{response.text=}')
#    assert response.status_code == 200

"""
settings.NOIDMINTER_URL
http://ddridservice.local:8002/noid/api/1.0/ddr.zeedeedk/

    
api/0.1/ ^noids/$ [name='noid-list']
api/0.1/ ^noids\.(?P<format>[a-z0-9]+)/?$ [name='noid-list']
api/0.1/ ^noids/(?P<pk>[^/.]+)/$ [name='noid-detail']
api/0.1/ ^noids/(?P<pk>[^/.]+)\.(?P<format>[a-z0-9]+)/?$ [name='noid-detail']
"""
