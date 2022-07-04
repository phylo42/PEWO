import os
import unittest

from pewo.io.jplace import JPlaceParser


class TestJPlaceParser(unittest.TestCase):

    JPLACE_EPANG = os.path.join("test", "pewo", "static", "0_r150_k7_o2.0_red0.99_arRAXMLNG_rappas.jplace")
    JPLACE_APPSPAM = os.path.join("test", "pewo", "static", "0_r150_k7_o2.0_red0.99_arRAXMLNG_rappas.jplace")
    JPLACE_PPLACER = os.path.join("test", "pewo", "static", "0_r150_k7_o2.0_red0.99_arRAXMLNG_rappas.jplace")

    def test_parser_rappas(self):
        jplace_dummy = os.path.join("test", "pewo", "static", "dummy.nwk")
        parser = JPlaceParser(jplace_dummy, False)
        for placement in parser.get_placements():
            print(placement)
        self.assertEqual(True, True)

    # def test_parser_rappas(self):
    #     jplace_rappas = os.path.join("test", "pewo", "static", "0_r150_k7_o2.0_red0.99_arRAXMLNG_rappas.jplace")
    #     parser = JPlaceParser(jplace_rappas, True)
    #     for placement in parser.get_placements():
    #         print(placement)
    #     self.assertEqual(True, True)


if __name__ == '__main__':
    unittest.main()
