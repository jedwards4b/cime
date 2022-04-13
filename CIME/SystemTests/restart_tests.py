"""
Abstract class for restart tests

"""

from CIME.SystemTests.system_tests_compare_two import SystemTestsCompareTwo
from CIME.XML.standard_module_setup import *
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta

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
    ):
        SystemTestsCompareTwo.__init__(
            self,
            case,
            separate_builds,
            run_two_suffix=run_two_suffix,
            run_one_description=run_one_description,
            run_two_description=run_two_description,
            multisubmit=multisubmit,
        )

    def _case_one_setup(self):
        stop_n = self._case1.get_value("STOP_N")
        expect(stop_n >= 3, "STOP_N must be at least 3, STOP_N = {}".format(stop_n))

    def _case_two_setup(self):
        rest_n = self._case1.get_value("REST_N")
        stop_n = self._case1.get_value("STOP_N")
        startdate = self._case1.get_value("RUN_STARTDATE")
        starttod = self._case1.get_value("START_TOD")
        restoption = self._case1.get_value("REST_OPTION")
        sdate = datetime.fromisoformat(f"{startdate}") + timedelta(seconds=starttod)

        if restoption.startswith("nhour"):
            rpdate = sdate + timedelta(hours=rest_n)
        elif restoption.startswith("nmonth"):
            rpdate = sdate + relativedelta(months=rest_n)
        elif restoption.startswith("nyear"):
            rpdate = sdate + relativedelta(years=rest_n)
        elif restoption.startswith("nday"):
            rpdate = sdate + timedelta(days=rest_n)
        elif restoption.startswith("nminute"):
            rpdate = sdate + timedelta(minutes=rest_n)
        elif restoption.startswith("nsecond"):
            rpdate = sdate + timedelta(seconds=rest_n)
        elif restoption.startswith("nstep"):
            ncpl = 0
            ncpl_base = self._case1.get_value("NCPL_BASE_PERIOD")
            for compclass in self._case1.get_values("COMP_CLASSES"):
                comp_ncpl = self._case1.get_value("{}_NCPL".format(compclass))
                if comp_ncpl is not None:
                    ncpl = max(ncpl, comp_ncpl)
            if ncpl_base == "day":
                rpdate = sdate + timedelta(seconds=(86400 / ncpl))
            elif ncpl_base == "hour":
                rpdate = sdate + timedelta(seconds=(3600 / ncpl))
            elif ncpl_base == "year":
                rpdate = sdate + relativedelta(years=(1.0 / ncpl))
            elif ncpl_base == "decade":
                rpdate = sdate + relativedelta(years=(10.0 / ncpl))
        elif restoption == "date":
            rpdate = datetime.fromisoformat(self._case1.get_value("REST_DATE"))

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
        self._case.set_value(
            "RPOINTER_TIMESTAMP_DATE",
            "{0:04d}-{1:02d}-{2:02d}".format(rpdate.year, rpdate.month, rpdate.day),
        )
        self._case.set_value(
            "RPOINTER_TIMESTAMP_TOD",
            "{0:05d}".format(
                int(rpdate.hour * 3600 + rpdate.minute * 60 + rpdate.second)
            ),
        )
