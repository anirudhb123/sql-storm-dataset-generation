SELECT 
    CONCAT('Part: ', p_name, ' | Brand: ', p_brand, ' | Type: ', p_type, 
           ' | Retail Price: $', FORMAT(p_retailprice, 2), ' | Comment: ', p_comment) AS part_details,
    s_name AS supplier_name,
    CONCAT(c_name, ' (', c_address, ')') AS customer_info,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
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
    p.p_size IN (10, 20, 30)
    AND s.s_acctbal > 1000
    AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.p_partkey, s.s_suppkey, c.c_custkey
ORDER BY 
    total_revenue DESC
LIMIT 50;
