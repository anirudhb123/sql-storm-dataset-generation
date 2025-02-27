SELECT 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Nation: ', n.n_name) AS supplier_part_nation,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    GROUP_CONCAT(DISTINCT o.o_orderkey ORDER BY o.o_orderdate DESC SEPARATOR ', ') AS order_list
FROM 
    partsupp ps
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_comment LIKE '%fragile%'
GROUP BY 
    supplier_part_nation
HAVING 
    total_available_quantity > 100
ORDER BY 
    average_supply_cost DESC;
