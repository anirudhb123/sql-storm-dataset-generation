SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s.s_name) AS supplier_count,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    r.r_name AS region_name,
    STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
    SUM(o.o_totalprice) AS total_order_value,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(o.o_orderdate) AS first_order_date
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    LENGTH(p.p_name) > 10 
    AND o.o_orderstatus = 'F'
GROUP BY 
    SUBSTRING(p.p_name, 1, 10), r.r_name
ORDER BY 
    total_order_value DESC, region_name;
