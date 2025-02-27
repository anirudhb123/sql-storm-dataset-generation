SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT ps.ps_partkey) AS part_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(p.p_retailprice) AS max_retail_price,
    MIN(p.p_retailprice) AS min_retail_price,
    STRING_AGG(DISTINCT p.p_type, ', ') AS unique_part_types,
    r.r_name AS region_name,
    n.n_name AS nation_name
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
    p.p_retailprice > 50.00
    AND s.s_acctbal >= 10000.00
    AND p.p_name LIKE '%widget%'
GROUP BY 
    s.s_name, r.r_name, n.n_name
ORDER BY 
    total_available_quantity DESC, supplier_name ASC;
