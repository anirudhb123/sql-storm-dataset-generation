SELECT 
    concat(c.c_name, ' (', c.c_acctbal, ')') AS customer_info, 
    concat(s.s_name, ' - ', s.s_address) AS supplier_info,
    concat(r.r_name, ' (', r.r_comment, ')') AS region_info,
    substring(p.p_name from 1 for 10) AS short_part_name,
    count(DISTINCT o.o_orderkey) AS total_orders,
    sum(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
    part p ON l.l_partkey = p.p_partkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND p.p_type LIKE '%plastic%'
GROUP BY 
    customer_info, supplier_info, region_info, short_part_name
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
