"""
Abstract class for restart tests

"""

from CIME.SystemTests.system_tests_compare_two import SystemTestsCompareTwo
from CIME.XML.standard_module_setup import *
from CIME.utils import set_directory
import glob
logger = logging.getLogger(__name__)


class RestartTest(SystemTestsCompareTwo):
    def __init__(
        self,
        case,
        separate_builds,
        run_two_suffix="restart",
        run_one_description="initial",
        run_two_description="restart",
        multisubmit=False,
        **kwargs
    ):
        SystemTestsCompareTwo.__init__(
            self,
            case,
            separate_builds,
            run_two_suffix=run_two_suffix,
            run_one_description=run_one_description,
            run_two_description=run_two_description,
            multisubmit=multisubmit,
            **kwargs
        )

    def _case_one_setup(self):
        stop_n = self._case1.get_value("STOP_N")
        expect(stop_n >= 3, "STOP_N must be at least 3, STOP_N = {}".format(stop_n))

    def _case_two_setup(self):
        rest_n = self._case1.get_value("REST_N")
        rest_option = self._case1.get_value("REST_OPTION")
        stop_n = self._case1.get_value("STOP_N")
        stop_new = stop_n - rest_n
        expect(
            stop_new > 0,
            "ERROR: stop_n value {:d} too short {:d} {:d}".format(
                stop_new, stop_n, rest_n
            ),
        )
        # hist_n is set to the stop_n value of case1
        self._case.set_value("HIST_N", stop_n)
        self._case.set_value("STOP_N", stop_new)
        self._case.set_value("CONTINUE_RUN", True)
        self._case.set_value("REST_OPTION", "never")



    def _case_one_custom_postrun_action(self):
        # Create a link from the previous rpointer.cpl. file to rpointer.cpl
        case1run = self._case1.get_value("RUNDIR")
        with set_directory(case1run):
            results = sorted(glob.glob("rpointer.cpl.*[0-9]"))
            logger.info("Restarting from {}".format(results[-2]))
            os.symlink(results[-2], "rpointer.cpl")
        
