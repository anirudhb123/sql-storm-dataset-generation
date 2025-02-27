SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS number_of_suppliers, 
    AVG(ps.ps_supplycost) AS average_supply_cost,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CONCAT('Region: ', r.r_name, ' | Supplier Count: ', COUNT(DISTINCT ps.ps_suppkey)) AS region_supplier_info,
    REPLACE(SUBSTRING_INDEX(s.s_comment, ' ', 5), ' ', ', ') AS supplier_comment_snippet
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
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderstatus = 'O' 
    AND p.p_type LIKE '%BRASS%' 
    AND l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    p.p_name, r.r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
