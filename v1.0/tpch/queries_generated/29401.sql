SELECT 
    p.p_name,
    CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS product_details,
    COUNT(ps.ps_supplycost) AS total_suppliers,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    MAX(ps.ps_availqty) AS max_availability,
    r.r_name,
    SUBSTRING(n.n_comment, 1, 50) AS short_nation_comment,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customers_served
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
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_name, p.p_mfgr, p.p_brand, p.p_type, r.r_name, n.n_comment
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_supply_cost DESC, max_availability DESC;
