
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_retail_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    MIN(ps.ps_supplycost) AS min_supply_cost
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_name LIKE '%rubber%'
    AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    average_retail_price DESC, total_orders DESC;
