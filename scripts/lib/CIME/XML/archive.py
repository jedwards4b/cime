"""
Interface to the archive.xml file.  This class inherits from GenericXML.py
"""

from CIME.XML.standard_module_setup import *
from CIME.XML.generic_xml import GenericXML
from CIME.XML.files import Files
from CIME.utils import expect, get_model

logger = logging.getLogger(__name__)

class Archive(GenericXML):

    def __init__(self, infile=None, files=None):
        """
        initialize an object
        """
        if files is None:
            files = Files()
        schema = files.get_schema("ARCHIVE_SPEC_FILE")

        GenericXML.__init__(self, infile, schema)

    def setup(self, env_archive, components, files=None):
        if files is None:
            files = Files()

        components_node = env_archive.make_child("components", attributes={"version":"2.0"})

        model = get_model()
        if 'drv' not in components:
            components.append('drv')
        if 'dart' not in components and model == 'cesm':
            components.append('dart')

        for comp in components:
            infile = files.get_value("ARCHIVE_SPEC_FILE", {"component":comp})

            if infile is not None and os.path.isfile(infile):
                arch = Archive(infile=infile, files=files)
                specs = arch.get_optional_child(name="comp_archive_spec", attributes={"compname":comp})
            else:
                if infile is None:
                    logger.debug("No archive file defined for component {}".format(comp))
                else:
                    logger.debug("Archive file {} for component {} not found".format(infile,comp))

                specs = self.get_optional_child(name="comp_archive_spec", attributes={"compname":comp})

            if specs is None:
                logger.debug("No archive specs found for component {}".format(comp))
            else:
                logger.debug("adding archive spec for {}".format(comp))
                env_archive.add_child(specs, root=components_node)

    def get_all_config_archive_files(self, files):
        """
        Returns the list of ARCHIVE_SPEC_FILES that exist on disk as defined in config_files.xml
        """
        archive_spec_node = files.get_child("entry", {"id" : "ARCHIVE_SPEC_FILE"})
        component_nodes = files.get_children("value", root=files.get_child("values", root=archive_spec_node))
        config_archive_files = []
        for comp in component_nodes:
            compval = self.text(comp)
            if "COMP_ROOT_DIR" in compval:
                search = re.search("\$(COMP_ROOT_DIR_[^\/]+)", compval)
                if search:
                    match = search.group(1)
                    comp_root_dir_node = files.get_child("entry", {"id": match})
                    new_component_nodes = files.get_children("value",
                                                             root=files.get_child("values", root=comp_root_dir_node))
                    for new_comp in new_component_nodes:
                        newcompval = re.sub("\$COMP_ROOT_DIR_[^\/]+", self.text(new_comp), compval)
                        newcompval = files.get_resolved_value(newcompval)
                        if os.path.isfile(newcompval):
                            config_archive_files.append(newcompval)
            else:
                compval = files.get_resolved_value(self.text(comp))
                if os.path.isfile(compval):
                    config_archive_files.append(compval)

        return list(set(config_archive_files))
