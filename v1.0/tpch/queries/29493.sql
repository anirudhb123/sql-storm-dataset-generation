SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(p.p_retailprice) AS total_retail_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    SUM(CASE WHEN o.o_orderstatus = 'O' THEN l.l_quantity ELSE 0 END) AS total_ordered,
    AVG(p.p_size) AS avg_part_size,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS return_count
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
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
WHERE 
    r.r_name LIKE 'Asia%'
GROUP BY 
    r.r_name, n.n_name, s.s_name
HAVING 
    SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) > 10000
ORDER BY 
    total_retail_price DESC;
