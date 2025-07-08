
SELECT 
    p.p_name,
    s.s_name,
    SUM(CASE 
        WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE l.l_extendedprice 
    END) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_quantity) AS avg_quantity,
    LISTAGG(DISTINCT CONCAT(c.c_name, ' (', c.c_acctbal, ')'), ', ') AS customers
FROM 
    part p 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
WHERE 
    p.p_comment LIKE '%special%' 
    AND s.s_comment NOT LIKE '%bad supplier%' 
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' 
GROUP BY 
    p.p_name, s.s_name 
HAVING 
    SUM(CASE 
        WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE l.l_extendedprice 
    END) > 10000 
ORDER BY 
    total_revenue DESC;
