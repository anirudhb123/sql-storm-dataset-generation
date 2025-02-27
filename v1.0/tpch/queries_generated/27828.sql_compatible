
SELECT 
    CONCAT(s.s_name, ' from ', n.n_name) AS supplier_info,
    STRING_AGG(CONCAT(p.p_name, ' (', ps.ps_availqty, ' available)'), ', ' ORDER BY p.p_name) AS available_parts,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(o.o_orderdate) AS last_order_date
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    n.n_name LIKE 'A%' 
    AND p.p_retailprice > 50.00
GROUP BY 
    s.s_name, n.n_name, ps.ps_availqty, p.p_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_supply_cost DESC, last_order_date DESC;
