SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(p.p_retailprice) AS avg_retail_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    CAST(AVG(o.o_totalprice) AS DECIMAL(12, 2)) AS avg_order_value,
    MAX(l.l_shipdate) AS last_shipped_date
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_name LIKE '%network%'
    AND l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
GROUP BY 
    s.s_name, p.p_name
ORDER BY 
    total_available_qty DESC, avg_retail_price ASC;