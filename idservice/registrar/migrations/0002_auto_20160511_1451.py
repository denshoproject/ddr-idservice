# -*- coding: utf-8 -*-
# Generated by Django 1.9.6 on 2016-05-11 21:51
from __future__ import unicode_literals

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('registrar', '0001_initial'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='objectid',
            name='collection_id',
        ),
        migrations.AlterField(
            model_name='objectid',
            name='group',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='objectids', to='auth.Group'),
        ),
    ]
