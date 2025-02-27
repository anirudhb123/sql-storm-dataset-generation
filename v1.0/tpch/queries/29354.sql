SELECT 
    CONCAT(s.s_name, ' (', n.n_name, ')') AS supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT p.p_type, ', ') AS product_types,
    AVG(l.l_quantity) AS avg_quantity_per_order,
    MAX(p.p_retailprice) AS max_product_price
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND o.o_orderstatus = 'O'
GROUP BY 
    s.s_suppkey, s.s_name, n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;