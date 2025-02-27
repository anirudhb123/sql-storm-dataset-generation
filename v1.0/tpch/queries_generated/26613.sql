SELECT 
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name, 
           ', Region: ', r.r_name, ', Average Parts Supplied: ', AVG(ps.ps_availqty),
           ', Total Supply Cost: ', SUM(ps.ps_supplycost), 
           ', Remarks: ', GROUP_CONCAT(DISTINCT ps.ps_comment ORDER BY ps.ps_comment SEPARATOR '; ')) AS Supplier_Info
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
GROUP BY 
    s.s_suppkey, n.n_nationkey, r.r_regionkey
HAVING 
    AVG(ps.ps_availqty) > 50
ORDER BY 
    r.r_name, s.s_name;
