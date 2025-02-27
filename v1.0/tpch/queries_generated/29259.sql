SELECT 
    CONCAT('Supplier ', s_name, ' from ', n_name, ' supplies ', p_name, ' in ', r_name, ' region.') AS description,
    SUM(ps_availqty) AS total_available_quantity,
    AVG(ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT s_suppkey) AS unique_suppliers
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice > 50.00 
    AND r.r_name LIKE 'Asia%'
GROUP BY 
    s.s_name, n.n_name, r.r_name, p.p_name
HAVING 
    total_available_quantity > 1000
ORDER BY 
    total_available_quantity DESC;
