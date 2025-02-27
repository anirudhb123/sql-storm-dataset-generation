SELECT 
    p.p_brand, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    r.r_name AS region_name
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN 
    region AS r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem AS l ON l.l_partkey = p.p_partkey
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer AS c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_brand LIKE 'Brand#%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_brand, r.r_name
ORDER BY 
    supplier_count DESC, avg_price_after_discount ASC;