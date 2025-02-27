
SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT c.c_mktsegment, ', ') AS marketing_segments,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    CASE 
        WHEN AVG(ps.ps_supplycost) > 100 THEN 'High Cost' 
        WHEN AVG(ps.ps_supplycost) BETWEEN 50 AND 100 THEN 'Medium Cost' 
        ELSE 'Low Cost' 
    END AS cost_category
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
    p.p_name ILIKE '%widget%'
    AND s.s_acctbal > 500
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, p.p_comment
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC;
