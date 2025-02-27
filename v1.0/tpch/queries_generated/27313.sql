SELECT 
    CONCAT('Supplier: ', s.s_name, ' (', s.s_phone, ') from Nation: ', n.n_name) AS supplier_info,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT p.p_partkey) AS distinct_parts_supplied,
    MAX(p.p_retailprice) AS max_retail_price,
    MIN(p.p_retailprice) AS min_retail_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS supplied_parts_names
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    n.n_name LIKE '%land%'
GROUP BY 
    s.s_suppkey, s.s_name, s.s_phone, n.n_name
ORDER BY 
    total_available_quantity DESC, avg_supply_cost ASC;
