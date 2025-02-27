SELECT 
    CONCAT('Part:', p.p_name, ' (', p.p_brand, ') - ', p.p_comment) AS part_description,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(p.p_retailprice) AS max_retail_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    STRING_AGG(DISTINCT o.o_orderkey::text, ', ') AS order_keys
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
WHERE 
    LENGTH(p.p_name) > 10 
    AND p.p_retailprice > (SELECT AVG(p_sub.p_retailprice) FROM part p_sub)
GROUP BY 
    p.p_name, p.p_brand, p.p_comment, r.r_name, n.n_name, s.s_name
ORDER BY 
    total_available_quantity DESC
LIMIT 100;
