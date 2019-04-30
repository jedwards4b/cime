"""
API for interfacing cylc workflow tool
"""
from CIME.XML.standard_module_setup import *
from CIME.utils import execfile, run_cmd_no_fail

logger = logging.getLogger(__name__)

def setup_cylc(case, alert_addresses, cylc_suite_dir, postproc_xml, postprocess_path):
    if not postprocess_path:
        postprocess_path = os.environ.get('POSTPROCESS_PATH')
    if postprocess_path:
        activate_script = os.path.join(postprocess_path,"cesm-env2","activate_this.py")
        if os.path.isfile(activate_script):
            logger.info("activating postprocessing environment")
            execfile(activate_script)
            run_cmd("create_postprocess -caseroot {}".format(case._caseroot))
            if os.path.isfile(postproc_xml):
                os.chmod(postproc_xml, 0o777)
                run_cmd_no_fail(postproc_xml,verbose=True)

            run_cmd_no_fail("pp_config -value -caseroot {} --get STANDARDIZE_TIMERSERIES".format(case._caseroot), from_dir(os.path.join(case._caseroot,"postprocess")))

    else:
        logger.warning("No POSTPROCESS_PATH found")
