SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(CASE WHEN p.p_size > 10 THEN ps.ps_availqty ELSE 0 END) AS large_part_avail_qty,
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    MAX(o.o_totalprice) AS max_order_total_price
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    n.n_name LIKE 'N%'
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    nation_name;
