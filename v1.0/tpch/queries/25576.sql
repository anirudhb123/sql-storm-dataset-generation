
SELECT 
    CONCAT(c.c_name, ' from ', s.s_name) AS supplier_customer,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    COUNT(l.l_orderkey) AS lineitem_count
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
AND 
    l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    c.c_name, s.s_name, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    total_sales DESC, region_name;
