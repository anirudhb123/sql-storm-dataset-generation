SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount)
        ELSE NULL 
    END) AS average_return_price,
    STRING_AGG(DISTINCT CONCAT(n.n_name, ' (', n.n_nationkey, ')'), ', ') AS nations_supplied
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC, order_count DESC;
