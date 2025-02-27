SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_sales,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_discounted_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS product_names,
    MAX(l.l_shipdate) AS latest_ship_date,
    MIN(l.l_shipdate) AS earliest_ship_date
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    n.n_name LIKE 'A%' 
    AND l.l_returnflag = 'R'
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_sales DESC;
