import re
# lexical token symbols
DQUOTED, SQUOTED, UNQUOTED, COMMA, NEWLINE = xrange(5)

_pattern_tuples = (
    (r'"[^"]*"', DQUOTED),
    (r"'[^']*'", SQUOTED),
    (r",", COMMA),
    (r"$", NEWLINE), # matches end of string OR \n just before end of string
    (r"[^,\n]+", UNQUOTED), # order in the above list is important
    )
_matcher = re.compile(
    '(' + ')|('.join([i[0] for i in _pattern_tuples]) + ')',
    ).match
_toktype = [None] + [i[1] for i in _pattern_tuples]
# need dummy at start because re.MatchObject.lastindex counts from 1 

def csv_split(text):
    """Split a csv string into a list of fields.
    Fields may be quoted with " or ' or be unquoted.
    An unquoted string can contain both a " and a ', provided neither is at
    the start of the string.
    A trailing \n will be ignored if present.
    """
    fields = []
    pos = 0
    want_field = True
    while 1:
        m = _matcher(text, pos)
        if not m:
            raise ValueError("Problem at offset %d in %r" % (pos, text))
        ttype = _toktype[m.lastindex]
        if want_field:
            if ttype in (DQUOTED, SQUOTED):
                fields.append(m.group(0)[1:-1])
                want_field = False
            elif ttype == UNQUOTED:
                fields.append(m.group(0))
                want_field = False
            elif ttype == COMMA:
                fields.append("")
            else:
                assert ttype == NEWLINE
                fields.append("")
                break
        else:
            if ttype == COMMA:
                want_field = True
            elif ttype == NEWLINE:
                break
            else:
                print "*** Error dump ***", ttype, repr(m.group(0)), fields
                raise ValueError("Missing comma at offset %d in %r" % (pos, text))
        pos = m.end(0)
    return fields

result = csv_split('ABT, AEE, AEP, AVB, BMS, BMY, CAG, CEG, CINF, CL, CLX, CMS, CNP, CPB, CTL, D, DD, DTE, DUK, ED, EIX, ETR, EXC, FE, FII, FTR, GIS, HCBK, HCN, HCP, HNZ, HRB, INTC, IP, JNJ, K, KFT, KIM, KMB, LEG, LLTC, LLY, LMT, LO, MAT, MCHP, MO, MRK, NEE, NI, NOC, OKE, PAYX, PBCT, PBI, PCG, PCL, PEG, PEP, PFE, PGN, PLD, PM, PNW, POM, PPL, PSA, Q, RAI, RRD, SCG, SE, SO, SPG, SRE, SVU, SYY, T, TE, TEG, VTR, VZ, WIN, WM, XEL')
print result