SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Nation: ', n.n_name, ' | Region: ', r.r_name) AS supplier_info,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS average_quantity_ordered,
    MAX(l.l_tax) AS maximum_tax_rate,
    MIN(o.o_orderdate) AS first_order_date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    l.l_shipmode IN ('AIR', 'GROUND')
    AND r.r_name LIKE 'E%'
    AND o.o_orderdate >= DATE '1997-01-01'
GROUP BY 
    s.s_name, n.n_name, r.r_name
ORDER BY 
    total_revenue DESC, unique_customers DESC
LIMIT 10;