
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, CAST(s.s_name AS VARCHAR(255)) AS hierarchy_path
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, CONCAT(sh.hierarchy_path, ' -> ', s.s_name)
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE s.s_acctbal < sh.s_nationkey
)

SELECT 
    p.p_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sales_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    LISTAGG(DISTINCT sh.hierarchy_path, ', ') WITHIN GROUP (ORDER BY sh.hierarchy_path) AS supplier_hierarchy
FROM 
    part p
LEFT OUTER JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = l.l_suppkey
WHERE 
    (p.p_size > 5 OR p.p_container IS NULL)
    AND (l.l_tax BETWEEN 0.05 AND 0.09 OR l.l_discount IS NULL)
GROUP BY 
    p.p_name, sh.s_suppkey, sh.s_name, sh.s_nationkey, sh.hierarchy_path
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    avg_sales_price DESC NULLS LAST;
