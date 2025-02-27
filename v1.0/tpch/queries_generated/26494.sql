SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    CONCAT('Supplier: ', s.s_name, ', Country: ', n.n_name) AS supplier_info,
    SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_quantity) AS avg_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(DATE_FORMAT(o.o_orderdate, '%Y-%m')) AS latest_order_month,
    MIN(CAST(SUBSTRING(p.p_comment FROM 5 FOR 15) AS CHAR(15))) AS short_comment
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size BETWEEN 1 AND 25
    AND o.o_orderstatus = 'O'
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC
LIMIT 10;
