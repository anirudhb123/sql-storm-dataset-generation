SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    ROUND(AVG(ps.ps_supplycost), 2) AS average_supply_cost,
    STRING_AGG(DISTINCT s.s_name || ' (' || s.s_phone || ')', ', ') AS suppliers_contact_info,
    SUM(l.l_quantity) AS total_quantity_sold,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT o.o_orderpriority, ', ') AS distinct_order_priorities
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%steel%'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    total_revenue DESC
LIMIT 10;
