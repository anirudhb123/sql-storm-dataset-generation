SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS unique_parts,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(s.s_acctbal) AS average_supplier_account_balance,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 100.00
    AND n.n_name LIKE 'A%'
GROUP BY 
    r.r_name, n.n_name, s.s_name
ORDER BY 
    total_available_quantity DESC, region_name, supplier_name;
