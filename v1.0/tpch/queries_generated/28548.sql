SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_return_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sale_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(CONCAT_WS(': ', s.s_name, s.s_acctbal), ', ') AS supplier_info
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_return_quantity DESC, avg_sale_price DESC;
