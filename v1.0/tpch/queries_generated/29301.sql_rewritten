SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    SUM(l.l_quantity) AS total_quantity_sold,
    MAX(o.o_orderdate) AS last_order_date,
    STRING_AGG(DISTINCT s.s_name, '; ') AS supplier_names
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
    p.p_name LIKE '%rubber%' 
    AND s.s_acctbal > 1000.00 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY 
    total_quantity_sold DESC;