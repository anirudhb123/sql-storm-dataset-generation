SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT p.p_partkey) AS total_parts,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    STRING_AGG(DISTINCT r.r_name, ', ') AS region_names
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 100.00 AND 
    s.s_acctbal < 200.00 AND 
    p.p_size IN (10, 20, 30)
GROUP BY 
    s.s_name
ORDER BY 
    total_parts DESC, average_supply_cost ASC
LIMIT 10;
