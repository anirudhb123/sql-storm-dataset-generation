
SELECT 
    s.s_name AS supplier_name, 
    p.p_name AS part_name, 
    SUM(ps.ps_availqty) AS total_avail_qty, 
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost, 
    LISTAGG(DISTINCT p.p_type, ', ') WITHIN GROUP (ORDER BY p.p_type) AS part_types_sample,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    ROUND(AVG(l.l_discount), 2) AS average_discount
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_comment LIKE '%urgent%' 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_supply_cost DESC
LIMIT 10;
