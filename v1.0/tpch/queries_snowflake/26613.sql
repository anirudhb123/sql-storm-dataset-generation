
SELECT 
    'Supplier: ' || s.s_name || ', Nation: ' || n.n_name || 
    ', Region: ' || r.r_name || ', Average Parts Supplied: ' || AVG(ps.ps_availqty) || 
    ', Total Supply Cost: ' || SUM(ps.ps_supplycost) || 
    ', Remarks: ' || LISTAGG(DISTINCT ps.ps_comment, '; ') WITHIN GROUP (ORDER BY ps.ps_comment) AS Supplier_Info
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
GROUP BY 
    s.s_suppkey, s.s_name, n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
HAVING 
    AVG(ps.ps_availqty) > 50
ORDER BY 
    r.r_name, s.s_name;
