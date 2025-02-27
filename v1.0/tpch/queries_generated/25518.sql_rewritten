SELECT 
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUBSTRING(n.n_name FROM 1 FOR 10) AS nation_prefix,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    DATE_TRUNC('month', o.o_orderdate) AS month,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    CASE
        WHEN o.o_orderstatus = 'F' THEN 'Finished'
        WHEN o.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Other'
    END AS order_status_description
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
GROUP BY 
    month, n.n_name, o.o_orderstatus
ORDER BY 
    month DESC, unique_customers DESC;