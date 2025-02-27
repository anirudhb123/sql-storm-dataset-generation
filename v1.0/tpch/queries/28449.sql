
SELECT 
    p.p_name,
    p.p_brand,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    COUNT(l.l_orderkey) AS total_lineitems,
    STRING_AGG(DISTINCT CONCAT(l.l_comment, ': ', l.l_shipmode), '; ') AS shipping_details,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE 0 
    END) AS average_returned_revenue
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
    p.p_retailprice > 50.00 
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, p.p_brand, s.s_name, c.c_name, o.o_orderkey
HAVING 
    COUNT(l.l_orderkey) > 5
ORDER BY 
    total_revenue DESC;
