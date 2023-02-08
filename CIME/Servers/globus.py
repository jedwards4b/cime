"""
Globus Server class.  Interact with a server using Globus protocol
"""
# pylint: disable=super-init-not-called
from CIME.XML.standard_module_setup import *
from CIME.Servers.generic_server import GenericServer
from CIME.utils import run_cmd
import globus_sdk
from globus_sdk.scopes import TransferScopes
from globus_sdk.tokenstorage import SimpleJSONFileAdapter

logger = logging.getLogger(__name__)
CLIENT_ID = "e17ab7ed-dc5e-4faf-95c3-bee6e8f7f479"


class Globus(GenericServer):
    def __init__(self, address, user="", passwd="", local_endpoint_id=None):
        self._root_address = address
        self._local_endpoint_id = local_endpoint_id
        self._client = globus_sdk.NativeAppAuthClient(CLIENT_ID)
        self._transfer_client = self.login_and_get_transfer_client()
        self._task_data = None

    def fileexists(self, rel_path):
        endpoint, root = self._root_address.split(":")
        server_path = os.path.normpath(os.path.join(root, rel_path))
        if not self._transfer_client:
            self._initialize_server(endpoint)
        stat = self._transfer_client.operation_ls(endpoint, server_path)

        return stat

    # pylint: disable=arguments-differ
    def getfile(self, rel_path, full_path, wait=True):
        endpoint, root = self._root_address.split(":")
        server_path = os.path.normpath(os.path.join(root, rel_path))
        if not self._task_data:
            self._initialize_server(endpoint)

        self._task_data.add_item(server_path, full_path)
        if wait:
            self.complete_transfer()
        return True

    # pylint: disable=arguments-differ
    def getdirectory(self, rel_path, full_path, wait=True):
        endpoint, root = self._root_address.split(":")
        server_path = os.path.normpath(os.path.join(root, rel_path))
        if not self._task_data:
            self._initialize_server(endpoint)

        self._task_data.add_item(server_path, full_path, recursive=True)

        if wait:
            self.complete_transfer()

        return True

    def complete_transfer(self):
        try:
            task_doc = self._transfer_client.submit_transfer(self._task_data)
        except globus_sdk.TransferAPIError as err:
            if not err.info.consent_required:
                raise
            self._transfer_client = self.login_and_get_transfer_client(
                scopes=err.info.consent_required.required_scopes
            )
            task_doc = self._transfer_client.submit_transfer(self._task_data)
        self._transfer_client.task_wait(task_doc["task_id"])

    def _initialize_server(self, endpoint):
        self._task_data = globus_sdk.TransferData(
            self._transfer_client,
            source_endpoint=endpoint,
            destination_endpoint=self._local_endpoint_id,
        )

        # we will need to do the login flow potentially twice, so define it as a
        # function
        #
        # we default to using the Transfer "all" scope, but it is settable here
        # look at the ConsentRequired handler below for how this is used

    def login_and_get_transfer_client(self, scopes=TransferScopes.all):
        self._client.oauth2_start_flow(requested_scopes=scopes, refresh_tokens=True)
        my_file_adapter = SimpleJSONFileAdapter(
            os.path.expanduser("~/.cime/inputdatatokens.json")
        )
        if not my_file_adapter.file_exists():
            authorize_url = self._client.oauth2_get_authorize_url()
            print(f"Please go to this URL and login:\n\n{authorize_url}\n")

            auth_code = input("Please enter the code here: ").strip()
            tokens = self._client.oauth2_exchange_code_for_tokens(auth_code)
            transfer_tokens = tokens.by_resource_server["transfer.api.globus.org"]
        else:
            transfer_tokens = my_file_adapter.get_token_data("transfer.api.globus.org")

        authorizer = globus_sdk.RefreshTokenAuthorizer(
            transfer_tokens["refresh_token"],
            self._client,
            access_token=transfer_tokens["access_token"],
            expires_at=transfer_tokens["expires_at_seconds"],
            on_refresh=my_file_adapter.on_refresh,
        )
        if not my_file_adapter.file_exists():
            my_file_adapter.store(tokens)

        # return the TransferClient object, as the result of doing a login
        return globus_sdk.TransferClient(authorizer=authorizer)
