WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_nationkey, s_name, CAST(s_name AS varchar(100)) AS full_name, 1 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_nationkey, s.s_name, CONCAT(SH.full_name, ' > ', s.s_name), SH.level + 1
    FROM supplier s
    JOIN SupplierHierarchy SH ON s.s_nationkey = SH.s_nationkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank,
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    CASE 
        WHEN p.p_retailprice > 100 THEN 'Expensive' 
        WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Moderate' 
        ELSE 'Cheap' 
    END AS price_category
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE o.o_orderstatus IN ('O', 'F')
AND l.l_quantity > 0
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, n.n_name
HAVING TOTAL_SALES > 1000
ORDER BY total_sales DESC
LIMIT 10;
