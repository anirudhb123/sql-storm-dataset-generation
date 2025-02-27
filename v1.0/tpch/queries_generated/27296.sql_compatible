
SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT ps.ps_partkey) AS number_of_parts,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_account_balance,
    STRING_AGG(DISTINCT p.p_name, ', ' ORDER BY p.p_name) AS part_names,
    r.r_name AS region
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_container LIKE '%BOX%' 
    AND s.s_comment LIKE '%reliable%'
GROUP BY 
    s.s_name, r.r_name, s.s_acctbal
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC
FETCH FIRST 10 ROWS ONLY;
