SELECT 
    p.p_partkey,
    p.p_name,
    CONCAT('Supplier: ', s.s_name, ', Nation: ', n.n_name) AS supplier_info,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity_sold,
    AVG(l.l_extendedprice) AS avg_price_per_order,
    MAX(l.l_tax) AS max_tax,
    MIN(l.l_discount) AS min_discount,
    STRING_AGG(DISTINCT p.p_comment, '; ') AS consolidated_comments
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
    p.p_retailprice > 100.00 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-10-01'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, n.n_name
ORDER BY 
    total_quantity_sold DESC, avg_price_per_order ASC;