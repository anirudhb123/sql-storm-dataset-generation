SELECT 
    CONCAT(p.p_name, ' ', s.s_name) AS part_supplier,
    UPPER(p.p_mfgr) AS manufacturer,
    SUM(l.l_quantity) AS total_quantity,
    MAX(p.p_retailprice) AS max_price,
    MIN(l.l_discount) AS min_discount,
    AVG(CAST(SUBSTRING(s.s_comment, 1, 30) AS VARCHAR(30))) AS sample_comment,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_comment LIKE '%quality%'
AND 
    o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    p.p_name, s.s_name, p.p_mfgr, r.r_name
ORDER BY 
    total_quantity DESC, region_name ASC
LIMIT 10;
