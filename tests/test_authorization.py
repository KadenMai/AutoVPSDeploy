import importlib.util
import unittest
from pathlib import Path
s=importlib.util.spec_from_file_location('task', Path(__file__).parents[1]/'scripts/run-task.py')
m=importlib.util.module_from_spec(s); s.loader.exec_module(m)
class Authorization(unittest.TestCase):
    def event(self):
        return {'sender':{'login':'owner'},'issue':{'state':'open','user':{'login':'owner'},'labels':[{'name':'agent:ready'}]}}
    def test_allowed(self):
        self.assertEqual(m.validate(self.event(), ['owner'])['state'], 'open')
    def test_foreign_sender(self):
        e=self.event(); e['sender']['login']='stranger'
        with self.assertRaises(ValueError): m.validate(e,['owner'])
    def test_foreign_author(self):
        e=self.event(); e['issue']['user']['login']='stranger'
        with self.assertRaises(ValueError): m.validate(e,['owner'])
    def test_closed(self):
        e=self.event(); e['issue']['state']='closed'
        with self.assertRaises(ValueError): m.validate(e,['owner'])
    def test_missing_label(self):
        e=self.event(); e['issue']['labels']=[]
        with self.assertRaises(ValueError): m.validate(e,['owner'])
