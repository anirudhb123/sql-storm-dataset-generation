
SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_price, 
    CONCAT('Total Quantity: ', CAST(SUM(l.l_quantity) AS CHAR), 
           ', Avg Price: ', CAST(AVG(l.l_extendedprice) AS DECIMAL(10, 2))) AS summary,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%widget%'
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_name, r.r_name, n.n_name, s.s_name, c.c_name
ORDER BY 
    total_quantity DESC, avg_price ASC
LIMIT 10;
