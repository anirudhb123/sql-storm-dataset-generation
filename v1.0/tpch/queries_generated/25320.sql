SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(l.l_discount) AS max_discount,
    STRING_AGG(DISTINCT l.l_comment, ', ') AS comments_aggregated
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    CAST(o.o_orderdate AS varchar) LIKE '199%'
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;
