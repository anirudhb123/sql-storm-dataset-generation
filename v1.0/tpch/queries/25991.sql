SELECT 
    r.r_name AS region_name, 
    n.n_name AS nation_name, 
    COUNT(DISTINCT c.c_custkey) AS unique_customers, 
    SUM(o.o_totalprice) AS total_revenue, 
    AVG(l.l_extendedprice) AS avg_lineitem_price, 
    MAX(p.p_retailprice) AS max_part_price, 
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names_list 
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
    p.p_type LIKE '%metal%' 
    AND o.o_orderdate >= DATE '1996-01-01' 
    AND o.o_orderdate < DATE '1997-01-01' 
GROUP BY 
    r.r_name, n.n_name 
ORDER BY 
    total_revenue DESC, region_name, nation_name;