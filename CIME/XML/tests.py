"""
Interface to the config_tests.xml file.  This class inherits from GenericEntry
"""
from CIME.XML.standard_module_setup import *

from CIME import utils
from CIME.XML.generic_xml import GenericXML
from CIME.XML.files import Files

logger = logging.getLogger(__name__)


class Tests(GenericXML):
    def __init__(self, infile=None, files=None):
        """
        initialize an object interface to file config_tests.xml
        """
        if infile is None:
            if files is None:
                files = Files()
            infile = files.get_value("CONFIG_TESTS_FILE")
        GenericXML.__init__(self, infile)
        # append any component specific config_tests.xml files
        for comp in files.get_components("CONFIG_TESTS_FILE"):
            if comp is None:
                continue
            infile = files.get_value("CONFIG_TESTS_FILE", attribute={"component": comp})
            if os.path.isfile(infile):
                self.read(infile)

    def support_single_exe(self, testnames):
        valid, invalid = [], []

        for testname in testnames:
            parsed_testname = utils.parse_test_name(testname)

            test_node = self.get_test_node(parsed_testname[0])

            try:
                single_exe_node = self.get_child("ALLOW_SINGLE_EXE", root=test_node)
            except utils.CIMEError:
                single_exe_supported = False
            else:
                single_exe_supported = utils.convert_to_type(
                    self.text(single_exe_node), "logical"
                )

            if single_exe_supported:
                valid.append(testname)
            else:
                invalid.append(testname)

        return valid, invalid

    def get_test_node(self, testname):
        logger.debug("Get settings for {}".format(testname))
        node = self.get_child("test", {"NAME": testname})
        logger.debug("Found {}".format(self.text(node)))
        return node

    def print_values(self, skip_infrastructure_tests=True):
        """
        Print each test type and its description.

        If skip_infrastructure_tests is True, then this does not write
        information for tests with the attribute
        INFRASTRUCTURE_TEST="TRUE".
        """
        all_tests = []
        root = self.get_optional_child("testlist")
        if root is not None:
            all_tests = self.get_children("test", root=root)
        for one_test in all_tests:
            if skip_infrastructure_tests:
                infrastructure_test = self.get(one_test, "INFRASTRUCTURE_TEST")
                if (
                    infrastructure_test is not None
                    and infrastructure_test.upper() == "TRUE"
                ):
                    continue
            name = self.get(one_test, "NAME")
            desc = self.get_element_text("DESC", root=one_test)
            logger.info("{}: {}".format(name, desc))
