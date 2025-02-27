
SELECT 
    CONCAT('Supplier: ', s_name, ', Region: ', r_name) AS supplier_region,
    SUM(CASE WHEN l_returnflag = 'R' THEN l_quantity ELSE 0 END) AS total_returned_quantity,
    AVG(l_extendedprice * (1 - l_discount)) AS avg_discounted_price,
    STRING_AGG(DISTINCT p_name, ', ') AS parts_list,
    COUNT(DISTINCT c.c_custkey) AS distinct_customers
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
    l_shipdate >= '1997-01-01' AND l_shipdate < '1998-01-01'
GROUP BY 
    s_name, r_name
HAVING 
    SUM(CASE WHEN l_returnflag = 'R' THEN l_quantity ELSE 0 END) > 1000
ORDER BY 
    total_returned_quantity DESC, avg_discounted_price ASC;
