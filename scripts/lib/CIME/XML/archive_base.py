"""
Base class for archive files.  This class inherits from generic_xml.py
"""
from CIME.XML.standard_module_setup import *
from CIME.XML.generic_xml import GenericXML

logger = logging.getLogger(__name__)

class ArchiveBase(GenericXML):

    def get_entry(self, compname):
        return self.scan_optional_child('comp_archive_spec',
                                        attributes={"compname":compname})

    def get_file_node_text(self, attnames, archive_entry):
        nodes = []
        textvals = []
        for attname in attnames:
            nodes.extend(self.get_children(attname, root=archive_entry))
        for node in nodes:
            textvals.append(self.text(node))
        return textvals

    def get_rest_file_extensions(self, archive_entry):
        return self.get_file_node_text(['rest_file_extension'],archive_entry)

    def get_rest_file_regex(self, archive_entry):
        return self.get_file_node_text(['rest_file_regex'],archive_entry)

    def get_hist_file_extensions(self, archive_entry):
        return self.get_file_node_text(['hist_file_extension'],archive_entry)

    def get_hist_file_regex(self, archive_entry):
        return self.get_file_node_text(['hist_file_regex'],archive_entry)

    def get_entry_value(self, name, archive_entry):
        node = self.get_optional_child(name, root=archive_entry)
        if node is not None:
            return self.text(node)
        return None

    def get_latest_hist_files(self, model, from_dir, suffix="", ref_case=None):

        test_hists = self.get_all_hist_files(model, from_dir, suffix=suffix, ref_case=ref_case)
        latest_files = {}
        histlist = []
        regex = self.get_hist_file_regex(self.get_entry(model))
        for hist in test_hists:
            ext = _get_extension(model, hist, regex=regex)
            latest_files[ext] = hist

        for key in latest_files.keys():
            histlist.append(os.path.join(from_dir,latest_files[key]))
            # Special case for fv3gfs which outputs in cubed sphere tiles
            if "tile[1-6].nc" in key:
                for i in range(1,5):
                    new_file = latest_files[key].replace("tile6.nc","tile{}.nc".format(i))
                    histlist.append(os.path.join(from_dir, new_file))

        return histlist

    def get_all_hist_files(self, model, from_dir, suffix="", ref_case=None):
        dmodel = model
        if model == "cpl":
            dmodel = "drv"
        hist_files = []
        extensions = self.get_hist_file_extensions(self.get_entry(dmodel))
        regex = self.get_hist_file_regex(self.get_entry(dmodel))

        for ext in extensions:
            if 'initial' in ext:
                continue
            if ext.endswith('$') and len(suffix)>0:
                ext = ext[:-1]
            string = model+r'\d?_?(\d{4})?\.'+ext
            if suffix and len(suffix)>0:
                string += '.'+suffix+'$'

            logger.debug ("Regex is {}".format(string))

            pfile = re.compile(string)
            hist_files.extend([f for f in os.listdir(from_dir) if pfile.search(f)])

        for match in regex:
            pfile = re.compile(match)
            hist_files.extend([f for f in os.listdir(from_dir) if pfile.search(f)])

        if ref_case:
            hist_files = [h for h in hist_files if not (ref_case in os.path.basename(h))]

        hist_files = list(set(hist_files))
        hist_files.sort()
        logger.debug("get_all_hist_files returns {} for model {}".format(hist_files, model))
        return hist_files

def _get_extension(model, filepath, regex=None):
    r"""
    For a hist file for the given model, return what we call the "extension"

    model - The component model
    filepath - The path of the hist file
    regex - if provided is a list of regex patterns to match for filenames.  This allows for
            filename patterns that do not match the original filenaming convention.
            If None (or []) only filename patterns are matched.
    >>> _get_extension("cpl", "cpl.hi.nc")
    'hi'
    >>> _get_extension("cpl", "cpl.h.nc")
    'h'
    >>> _get_extension("cpl", "cpl.h1.nc.base")
    'h1'
    >>> _get_extension("cpl", "TESTRUNDIFF.cpl.hi.0.nc.base")
    'hi'
    >>> _get_extension("cpl", "TESTRUNDIFF_Mmpi-serial.f19_g16_rx1.A.melvin_gnu.C.fake_testing_only_20160816_164150-20160816_164240.cpl.h.nc")
    'h'
    >>> _get_extension("clm","clm2_0002.h0.1850-01-06-00000.nc")
    '0002.h0'
    >>> _get_extension("pop","PFS.f09_g16.B1850.cheyenne_intel.allactive-default.GC.c2_0_b1f2_int.pop.h.ecosys.nday1.0001-01-02.nc")
    'h'
    >>> _get_extension("fv3gfs", "dynf000.tile1.nc", regex=["^physf\d\d\d.tile[1-6].nc$","^dynf\d\d\d.tile[1-6].nc$"])
    '^dynf\\d\\d\\d.tile[1-6].nc$'
    >>> _get_extension("mom", "ga0xnw.mom6.frc._0001_001.nc")
    'frc'
    >>> _get_extension("mom", "ga0xnw.mom6.sfc.day._0001_001.nc")
    'sfc.day'
    >>> _get_extension("mom", "bixmc5.mom6.prog._0001_01_05_84600.nc")
    'prog'
    >>> _get_extension("mom", "bixmc5.mom6.hm._0001_01_03_42300.nc")
    'hm'
    >>> _get_extension("mom", "bixmc5.mom6.hmz._0001_01_03_42300.nc")
    'hmz'
    """
    basename = os.path.basename(filepath)
    m = None
    ext_regexes = []

    # First add any model-specific extension regexes; these will be checked before the
    # general regex
    if model == "mom":
        # Need to check 'sfc.day' specially: the embedded '.' messes up the
        # general-purpose regex
        ext_regexes.append(r'sfc\.day')

    # Now add the general-purpose extension regex
    ext_regexes.append(r'\w+')

    for ext_regex in ext_regexes:
        full_regex_str = model+r'\d?_?(\d{4})?\.('+ext_regex+r')[-\w\.]*\.nc\.?'
        full_regex = re.compile(full_regex_str)
        m = full_regex.search(basename)
        if m is not None:
            if m.group(1) is not None:
                result = m.group(1)+'.'+m.group(2)
            else:
                result = m.group(2)
            return result

    if regex:
        for result in regex:
            m = re.search(result, basename)
            if m:
                break
    expect(m, "Failed to get extension for file '{}'".format(filepath))

    return result
