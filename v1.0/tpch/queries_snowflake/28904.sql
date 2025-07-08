
SELECT 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(s.s_acctbal) AS average_supplier_balance, 
    LISTAGG(DISTINCT r.r_name, ', ') WITHIN GROUP (ORDER BY r.r_name) AS regions_supplied,
    SUBSTR(p.p_comment, 1, 20) AS short_comment,
    CASE 
        WHEN SUM(l.l_quantity) > 1000 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    customer c ON c.c_custkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%steel%' 
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_name, short_comment, total_quantity, average_supplier_balance, volume_category
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 2
ORDER BY 
    total_quantity DESC;
