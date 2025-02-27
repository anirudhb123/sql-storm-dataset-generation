SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_mfgr, 
    p.p_type, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_price, 
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MIN(o.o_orderdate) AS first_order_date,
    MAX(o.o_orderdate) AS last_order_date,
    CONCAT('Part: ', p.p_name, ' (', p.p_mfgr, ') - Total Orders: ', COUNT(DISTINCT o.o_orderkey)) AS summary_comment
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
    p.p_size >= 15 AND 
    o.o_orderstatus = 'O' AND 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_type
ORDER BY 
    total_quantity DESC, avg_price ASC
LIMIT 10;