WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)

SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS avg_order_value,
    CASE 
        WHEN AVG(l.l_quantity) > 100 THEN 'High Volume'
        WHEN AVG(l.l_quantity) IS NULL THEN 'No Sales'
        ELSE 'Low Volume'
    END AS sales_category
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierHierarchy sh ON sh.s_nationkey = l.l_suppkey 
WHERE 
    (o.o_orderstatus = 'F' OR o.o_orderstatus IS NULL)
    AND l.l_shipdate > '1997-01-01'
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue DESC
FETCH FIRST 10 ROWS ONLY;