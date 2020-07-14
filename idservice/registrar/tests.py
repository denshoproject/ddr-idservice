import pytest

from django.contrib.auth.models import Group, User
from django.test import Client, TestCase
from django.urls import reverse
from django.utils import timezone

from . import models
from DDR import config
from DDR import identifier
from DDR import idservice

USERNAME = 'admin'
PASSWORD = 'admin'
IDSERVICE_API_BASE = 'http://127.0.0.1:8082/api/0.1'


@pytest.fixture
def create_user(db, django_user_model):
   def make_user(**kwargs):
       kwargs['password'] = PASSWORD
       return django_user_model.objects.create_user(**kwargs)
   return make_user

def make_objectid(group, model, id):
    group, created = Group.objects.get_or_create(name=group)
    o = models.ObjectID(
        group=group, model=model, id=id,
        created=timezone.now(), modified=timezone.now()
    )
    o.save()
    return o


@pytest.mark.django_db
def test_groups(client, create_user):
    url = '/api/0.1/groups/'
    response = client.get(url)
    assert response.status_code == 200

@pytest.mark.django_db
def test_group(client, create_user):
    testing_group, created = Group.objects.get_or_create(name='testing')
    url = '/api/0.1/groups/{}/'.format(testing_group.id)
    response = client.get(url)
    assert response.status_code == 200

@pytest.mark.django_db
def test_users(client, create_user):
    url = '/api/0.1/users/'
    response = client.get(url)
    assert response.status_code == 401

@pytest.mark.django_db
def test_user(client, create_user):
    admin_user = create_user(
        username=USERNAME, password=PASSWORD, is_staff=1, is_superuser=1
    )
    url = '/api/0.1/users/1/'
    response = client.get(url)
    assert response.status_code == 401

@pytest.mark.django_db
def test_login(client, create_user):
    admin_user = create_user(
        username=USERNAME, password=PASSWORD, is_staff=1, is_superuser=1
    )
    client.login(username=USERNAME, password=PASSWORD)

@pytest.mark.django_db
def test_create(client, create_user):
    make_objectid('testing', 'collection', 'ddr-testing-1')
    make_objectid('testing', 'entity', 'ddr-testing-1-1')
    models.ObjectID.objects.get(id='ddr-testing-1')
    models.ObjectID.objects.get(id='ddr-testing-1-1')

@pytest.mark.django_db
def test_detail(client, create_user):
    # setup
    make_objectid('testing', 'collection', 'ddr-testing-1')
    make_objectid('testing', 'entity', 'ddr-testing-1-1')
    models.ObjectID.objects.get(id='ddr-testing-1')
    models.ObjectID.objects.get(id='ddr-testing-1-1')
    admin_user = create_user(
        username=USERNAME, password=PASSWORD, is_staff=1, is_superuser=1
    )
    # test
    client.login(username=USERNAME, password=PASSWORD)
    url = IDSERVICE_API_BASE + '/objectids/{}/'.format('ddr-testing-1')
    r = client.get(url)
    assert r.status_code == 200

@pytest.mark.django_db
def test_children(client, create_user):
    """Test that app returns list of children
    """
    # setup
    make_objectid('testing', 'collection', 'ddr-testing-1')
    make_objectid('testing', 'entity', 'ddr-testing-1-1')
    make_objectid('testing', 'entity', 'ddr-testing-1-2')
    models.ObjectID.objects.get(id='ddr-testing-1')
    models.ObjectID.objects.get(id='ddr-testing-1-1')
    models.ObjectID.objects.get(id='ddr-testing-1-2')
    admin_user = create_user(
        username=USERNAME, password=PASSWORD, is_staff=1, is_superuser=1
    )
    # test
    client.login(username=USERNAME, password=PASSWORD)
    url = IDSERVICE_API_BASE + '/objectids/{}/children/'.format('ddr-testing-1')
    r = client.get(url)
    assert r.status_code == 200
    print(r.data)
    assert isinstance(r.data, list)
    assert len(r.data) == 2
    assert r.data[0]['group'] == 'testing'
    assert r.data[0]['model'] == 'entity'
    assert r.data[0]['id'] == 'ddr-testing-1-1'
    assert r.data[1]['group'] == 'testing'
    assert r.data[1]['model'] == 'entity'
    assert r.data[1]['id'] == 'ddr-testing-1-2'

@pytest.mark.django_db
def test_check_collections(client, create_user):
    """Test that app 
    """
    # setup
    make_objectid('testing', 'collection', 'ddr-testing-1')
    models.ObjectID.objects.get(id='ddr-testing-1')
    admin_user = create_user(
        username=USERNAME, password=PASSWORD, is_staff=1, is_superuser=1
    )
    # test
    client.login(username=USERNAME, password=PASSWORD)
    url = IDSERVICE_API_BASE + '/objectids/{}/check/'.format('ddr-testing-1')
    data = {'object_ids': ['ddr-testing-1','ddr-testing-2']}
    r = client.post(url, data=data)
    print(r.data)
    assert isinstance(r.data, dict)
    assert isinstance(r.data['registered'], list)
    assert isinstance(r.data['unregistered'], list)
    assert len(r.data['registered']) == 1
    assert len(r.data['unregistered']) == 1
    assert 'ddr-testing-1' in r.data['registered']
    assert 'ddr-testing-2' in r.data['unregistered']

@pytest.mark.django_db
def test_check_entities(client, create_user):
    """Test that app 
    """
    # setup
    make_objectid('testing', 'collection', 'ddr-testing-1')
    make_objectid('testing', 'entity', 'ddr-testing-1-1')
    make_objectid('testing', 'entity', 'ddr-testing-1-2')
    models.ObjectID.objects.get(id='ddr-testing-1')
    models.ObjectID.objects.get(id='ddr-testing-1-1')
    models.ObjectID.objects.get(id='ddr-testing-1-2')
    admin_user = create_user(
        username=USERNAME, password=PASSWORD, is_staff=1, is_superuser=1
    )
    # test
    client.login(username=USERNAME, password=PASSWORD)
    url = IDSERVICE_API_BASE + '/objectids/{}/check/'.format('ddr-testing-1')
    data = {'object_ids': [
        'ddr-testing-1-1','ddr-testing-1-2','ddr-testing-1-3',
    ]}
    r = client.post(url, data=data)
    print(r.data)
    assert isinstance(r.data, dict)
    assert isinstance(r.data['registered'], list)
    assert isinstance(r.data['unregistered'], list)
    assert len(r.data['registered']) == 2
    assert len(r.data['unregistered']) == 1
    assert 'ddr-testing-1-1' in r.data['registered']
    assert 'ddr-testing-1-2' in r.data['registered']
    assert 'ddr-testing-1-3' in r.data['unregistered']

@pytest.mark.django_db
def test_next_collection(client, create_user):
    """Test if app can get or post next collection
    """
    # setup
    make_objectid('testing', 'collection', 'ddr-testing-1')
    models.ObjectID.objects.get(id='ddr-testing-1')
    admin_user = create_user(
        username=USERNAME, password=PASSWORD, is_staff=1, is_superuser=1
    )
    # test
    client.login(username=USERNAME, password=PASSWORD)
    url = IDSERVICE_API_BASE + '/objectids/{}/next/{}/'.format(
        'ddr-testing', 'collection'
    )
    # GET
    print(url)
    r = client.get(url)
    assert r.status_code == 200
    print(r.data)
    assert isinstance(r.data, dict)
    assert r.data['group'] == 'testing'
    assert r.data['model'] == 'collection'
    assert r.data['id'] == 'ddr-testing-2'
    # POST
    print(url)
    r = client.post(url)
    assert r.status_code == 201
    print(r.data)
    assert isinstance(r.data, dict)
    assert r.data['group'] == 'testing'
    assert r.data['model'] == 'collection'
    assert r.data['id'] == 'ddr-testing-2'
    o = models.ObjectID.objects.get(id='ddr-testing-2')
    print(o)

@pytest.mark.django_db
def test_next_entity(client, create_user):
    """Test if app can get or post next entity
    """
    # setup
    make_objectid('testing', 'collection', 'ddr-testing-1')
    make_objectid('testing', 'entity', 'ddr-testing-1-1')
    models.ObjectID.objects.get(id='ddr-testing-1')
    models.ObjectID.objects.get(id='ddr-testing-1-1')
    admin_user = create_user(
        username=USERNAME, password=PASSWORD, is_staff=1, is_superuser=1
    )
    # test
    client.login(username=USERNAME, password=PASSWORD)
    url = IDSERVICE_API_BASE + '/objectids/{}/next/{}/'.format(
        'ddr-testing-1', 'entity'
    )
    # GET
    print(url)
    r = client.get(url)
    assert r.status_code == 200
    print(r.data)
    assert isinstance(r.data, dict)
    assert r.data['group'] == 'testing'
    assert r.data['model'] == 'entity'
    assert r.data['id'] == 'ddr-testing-1-2'
    # POST
    print(url)
    r = client.post(url)
    assert r.status_code == 201
    print(r.data)
    assert isinstance(r.data, dict)
    assert r.data['group'] == 'testing'
    assert r.data['model'] == 'entity'
    assert r.data['id'] == 'ddr-testing-1-2'

@pytest.mark.django_db
def test_create_collections(client, create_user):
    """Test that app 
    """
    # setup
    make_objectid('testing', 'collection', 'ddr-testing-1')
    models.ObjectID.objects.get(id='ddr-testing-1')
    admin_user = create_user(
        username=USERNAME, password=PASSWORD, is_staff=1, is_superuser=1
    )
    # test
    client.login(username=USERNAME, password=PASSWORD)
    url = IDSERVICE_API_BASE + '/objectids/{}/create/'.format('ddr-testing')
    data = {'object_ids': [
        'ddr-testing-2','ddr-testing-3'
    ]}
    r = client.post(url, data=data)
    print(r.data)
    assert isinstance(r.data, dict)
    assert isinstance(r.data['created'], list)
    assert len(r.data['created']) == 2
    assert 'ddr-testing-2' in r.data['created']
    assert 'ddr-testing-3' in r.data['created']

@pytest.mark.django_db
def test_create_entities(client, create_user):
    """Test that app 
    """
    # setup
    make_objectid('testing', 'collection', 'ddr-testing-1')
    make_objectid('testing', 'entity', 'ddr-testing-1-1')
    models.ObjectID.objects.get(id='ddr-testing-1')
    models.ObjectID.objects.get(id='ddr-testing-1-1')
    admin_user = create_user(
        username=USERNAME, password=PASSWORD, is_staff=1, is_superuser=1
    )
    # test
    client.login(username=USERNAME, password=PASSWORD)
    url = IDSERVICE_API_BASE + '/objectids/{}/create/'.format('ddr-testing-1')
    data = {'object_ids': [
        'ddr-testing-1-2','ddr-testing-1-3',
    ]}
    r = client.post(url, data=data)
    print(r.data)
    assert isinstance(r.data, dict)
    assert isinstance(r.data['created'], list)
    assert len(r.data['created']) == 2
    assert 'ddr-testing-1-2' in r.data['created']
    assert 'ddr-testing-1-3' in r.data['created']
