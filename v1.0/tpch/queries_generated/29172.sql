SELECT 
    p.p_name,
    CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand) AS mfgr_brand,
    GROUP_CONCAT(DISTINCT CONCAT('Supplier: ', s.s_name, ' (', s.s_address, ')') ORDER BY s.s_name SEPARATOR '; ') AS supplier_info,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    ROUND(AVG(CASE WHEN c.c_mktsegment = 'BUILDING' THEN o.o_totalprice END), 2) AS avg_building_order_value,
    MIN(o.o_orderdate) AS first_order_date,
    MAX(o.o_orderdate) AS last_order_date,
    COUNT(DISTINCT c.c_custkey) AS distinct_customers
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_comment LIKE '%box%'
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC
LIMIT 10;
