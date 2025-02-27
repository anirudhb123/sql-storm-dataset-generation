SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(l.l_shipdate) AS last_ship_date,
    MIN(l.l_shipdate) AS first_ship_date,
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_nation_info,
    REGEXP_REPLACE(p.p_comment, 'sensitive|confidential|proprietary', '') AS sanitized_comment
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    o.o_orderstatus = 'O' 
    AND l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2023-01-01'
GROUP BY 
    p.p_name, s.s_suppkey, n.n_nationkey
HAVING 
    revenue > 10000
ORDER BY 
    revenue DESC, p.p_name;
