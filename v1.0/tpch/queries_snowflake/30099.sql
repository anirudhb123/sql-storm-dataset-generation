
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, NULL AS parent_suppkey
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)  

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.s_suppkey AS parent_suppkey
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.parent_suppkey
    WHERE s.s_acctbal < sh.s_acctbal  
)

SELECT 
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank,
    sr.r_name AS region,
    n.n_name AS nation,
    COALESCE(s.s_name, 'Unknown') AS supplier_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region sr ON n.n_regionkey = sr.r_regionkey
WHERE 
    l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1997-12-31' 
    AND o.o_orderstatus = 'O'
    AND EXISTS ( 
        SELECT 1 
        FROM supplier_hierarchy sh 
        WHERE sh.s_suppkey = s.s_suppkey 
    )
GROUP BY 
    p.p_partkey, p.p_name, n.n_name, sr.r_name, s.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000 OR 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_sales DESC, rank;
