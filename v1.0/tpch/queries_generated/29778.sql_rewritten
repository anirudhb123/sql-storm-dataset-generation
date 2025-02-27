SELECT 
    p.p_name,
    s.s_name,
    COUNT(*) AS supplier_count,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    STRING_AGG(DISTINCT CONCAT('OrderID: ', o.o_orderkey, ', Total Price: ', o.o_totalprice), '; ') AS order_details
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
    p.p_comment LIKE '%metal%'
    AND s.s_comment NOT LIKE '%discount%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name
HAVING 
    COUNT(*) > 5
ORDER BY 
    avg_supply_cost DESC;