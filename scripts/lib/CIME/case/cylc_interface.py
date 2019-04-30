"""
API for interfacing cylc workflow tool
"""
from CIME.XML.standard_module_setup import *
from CIME.utils import execfile, run_cmd_no_fail

logger = logging.getLogger(__name__)

def setup_cylc(case, alert_addresses, cylc_suite_path, postproc_xml, postprocess_path,
               conform_path):
    if not postprocess_path:
        postprocess_path = os.environ.get('POSTPROCESS_PATH')
    if postprocess_path:
        # fix this - we shouldn't be required to set these.
        os.environ['POSTPROCESS_PATH']=postprocess_path
        os.environ['POSTPROCESS_PATH_GEYSER']=postprocess_path
        activate_script = os.path.join(postprocess_path,"cesm-env2","bin","activate_this.py")
        if os.path.isfile(activate_script):
            logger.info("activating postprocessing environment in {}".format(case._caseroot))
            execfile(activate_script)
            run_cmd("create_postprocess -caseroot {}".format(case._caseroot), from_dir=case._caseroot)
            if postproc_xml and os.path.isfile(postproc_xml):
                os.chmod(postproc_xml, 0o777)
                run_cmd_no_fail(postproc_xml,verbose=True)
            # This should return true or false but it just seems to echo the variable
            conform = True
            #            conform = run_cmd("pp_config --value --caseroot {} --get STANDARDIZE_TIMERSERIES".format(case._caseroot), from_dir=os.path.join(case._caseroot,"postprocess"), verbose=True)
            if conform:
                expect(os.path.isdir(conform_path),"Conform input directory not found {}".format(conform_path))
                compset = case.get_value("COMPSET")
                grid = case.get_value("GRID")
                if 'CAM60%W' in compset:
                    # settings for WACCM
                    run_cmd("pp_config --set CONFORM_CESM_DEFINITIONS={}".format(os.path.join(conform_path,"CESM_WACCM_MastList.def")), from_dir=os.path.join(case._caseroot,"postprocess"), verbose=True)
                elif 'a%ne120' in grid:
                    # Settings for hires
                    run_cmd("pp_config --set CONFORM_CESM_DEFINITIONS={}".format(os.path.join(conform_path,"CESM_HIRES_MastList.def")), from_dir=os.path.join(case._caseroot,"postprocess"), verbose=True)
                elif 'DATM' in compset and 'CLM' in compset:
                    # settings for CLM standalone runs
                    run_cmd("pp_config --set CONFORM_CLM_DEFINITIONS={}".format(os.path.join(conform_path,"CESM_WACCM_MastList.def")), from_dir=os.path.join(case._caseroot,"postprocess"), verbose=True)
            queue = None
            run_cmd("CESM_Cylc_setup -c {cimeroot} -p {cylc_suite_path}/{casename} -s {casename}.suite.cmip6 -d {caseroot} -g workflow.png -e {alert_addresses} -m {machine} -q {queue} -u cmip6".format(cimeroot=case.get_value("CIMEROOT"),
                            casename=case.get_value("CASE"),
                            caseroot=case.get_value("CASEROOT"),
                            alert_addresses=alert_addresses,
                            machine=case.get_value("MACH"),
                            cylc_suite_path=cylc_suite_path,
                                                                                                                                                                                                queue=queue), from_dir=case.get_value("CASETOOLS"), verbose=True)
    else:
        logger.warning("No POSTPROCESS_PATH found")
