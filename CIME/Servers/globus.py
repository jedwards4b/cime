"""
Globus Server class.  Interact with a server using Globus protocol
"""
# pylint: disable=super-init-not-called
from CIME.XML.standard_module_setup import *
from CIME.Servers.generic_server import GenericServer
from CIME.utils import run_cmd

logger = logging.getLogger(__name__)


class Globus(GenericServer):
    def __init__(self, address, user="", passwd="", local_endpoint_id=None):
        self._root_address = address
        self._local_endpoint_id = local_endpoint_id

    def fileexists(self, rel_path):
        stat, out, err = run_cmd(
            "globus ls {}".format(
                os.path.join(self._root_address, os.path.dirname(rel_path)) + os.sep
            )
        )
        if stat or os.path.basename(rel_path) not in out:
            logging.warning(
                "FAIL: File {} not found.\nstat={} error={}".format(rel_path, stat, err)
            )
            return False
        return True

    def getfile(self, rel_path, full_path):
        endpoint, root = self._root_address.split(":")
        server_path = os.path.normpath(os.path.join(root, rel_path))
        stat, out, err = run_cmd(
            "globus transfer -v {}:{} {}:{}".format(
                endpoint, server_path, self._local_endpoint_id, full_path
            ),
            verbose=True,
        )

        if stat != 0:
            logging.warning(
                "FAIL: GLOBUS repo '{}' does not have file '{}' error={}\n".format(
                    self._root_address, rel_path, err
                )
            )
            return False

        self._wait_for_completion(out)
        return True

    def getdirectory(self, rel_path, full_path):
        endpoint, root = self._root_address.split(":")
        server_path = os.path.normpath(os.path.join(root, rel_path))
        stat, out, err = run_cmd(
            "globus transfer --recursive --label {}:{}{} {}:{}{}".format(
                endpoint,
                server_path,
                os.sep,
                self._local_endpoint_id,
                full_path,
                os.sep,
            )
        )

        if stat != 0:
            logging.warning(
                "FAIL: Globus repo '{}' does not have directory '{}' error={}\n".format(
                    self._root_address, rel_path, err
                )
            )
            return False
        self._wait_for_completion(out)
        return True

    @staticmethod
    def _wait_for_completion(out):
        task_id = out.split("Task ID:")[1]
        stat, _, err = run_cmd("globus task -v wait {}".format(task_id), verbose=True)
        if stat != 0:
            logging.warning("FAIL: Globus task failed with error:", err)
            return False
