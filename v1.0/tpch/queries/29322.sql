
SELECT 
    p.p_name,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice ELSE 0 END) AS total_filled_orders,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    MAX(p.p_retailprice) AS max_retail_price,
    MIN(CASE WHEN c.c_mktsegment = 'AUTOMOBILE' THEN c.c_acctbal ELSE NULL END) AS min_autos_acctbal
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_brand LIKE 'Brand%' 
    AND s.s_acctbal > 1000
GROUP BY 
    p.p_name, p.p_comment
ORDER BY 
    supplier_count DESC, avg_supplier_acctbal DESC
LIMIT 50;
