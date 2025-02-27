SELECT 
    p.p_name,
    s.s_name AS supplier_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    CONCAT('Region: ', r.r_name, ' - Size: ', p.p_size) AS part_details,
    (SELECT COUNT(*) 
     FROM orders o 
     JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
     WHERE l.l_partkey = p.p_partkey AND o.o_orderstatus = 'O') AS total_orders
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
WHERE 
    p.p_comment LIKE '%special%' AND
    p.p_size BETWEEN 10 AND 50
GROUP BY 
    p.p_name, s.s_name, r.r_name, p.p_size
HAVING 
    total_available_quantity > 100
ORDER BY 
    total_available_quantity DESC, avg_supply_cost ASC;
