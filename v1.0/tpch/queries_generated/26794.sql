SELECT 
    s.s_name AS supplier_name,
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS location,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS supplied_parts,
    (SELECT AVG(o.o_totalprice) 
     FROM orders o 
     WHERE o.o_custkey IN (SELECT c.c_custkey 
                           FROM customer c 
                           WHERE c.c_nationkey = s.s_nationkey)) AS average_order_value
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
    p.p_comment LIKE '%special%' OR s.s_comment LIKE '%important%'
GROUP BY 
    s.s_name, r.r_name, n.n_name
ORDER BY 
    total_available_quantity DESC;
