SELECT 
    p.p_name,
    COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(l.l_extendedprice) AS max_lineitem_price,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
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
    p.p_comment LIKE '%fragile%'
    AND l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    supplier_count DESC, total_available_quantity ASC;
