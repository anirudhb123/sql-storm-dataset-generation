
SELECT 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS supplier_part_info,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS average_price_after_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment,
    r.r_name AS region_name
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
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate < '1998-01-01' 
    AND s.s_comment LIKE '%quality%' 
GROUP BY 
    s.s_suppkey, p.p_partkey, s.s_name, p.p_name, r.r_name, p.p_comment
ORDER BY 
    total_quantity DESC, average_price_after_discount DESC
LIMIT 10;
