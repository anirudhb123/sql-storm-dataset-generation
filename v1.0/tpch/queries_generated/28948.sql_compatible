
SELECT 
    CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name) AS supplier_region,
    COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT p.p_type, ', ') AS part_types
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
    p.p_retailprice > 100.00 
    AND s.s_acctbal > 1000.00
GROUP BY 
    s.s_suppkey, s.s_name, r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC;
