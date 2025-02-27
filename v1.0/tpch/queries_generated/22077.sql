WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_comment
    FROM part p
    WHERE p.p_retailprice = (SELECT MAX(p2.p_retailprice) FROM part p2 WHERE p2.p_size BETWEEN 1 AND 20)
    AND p.p_comment IS NOT NULL
),
SalesSummary AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' 
    AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(ss.total_sales, 0) AS sales,
    sh.s_name AS supplier_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    CASE 
        WHEN p.p_comment LIKE '%special%' THEN 'Special Item'
        ELSE 'Regular Item'
    END AS item_type,
    RANK() OVER (PARTITION BY sh.level ORDER BY COALESCE(ss.total_sales, 0) DESC) AS sales_rank
FROM FilteredParts p
LEFT JOIN SalesSummary ss ON p.p_partkey = ss.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN customer c ON c.c_nationkey = sh.s_nationkey
WHERE sh.s_acctbal > (
    SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IS NOT NULL
)
OR sh.s_acctbal IS NULL
GROUP BY p.p_partkey, p.p_name, p.p_retailprice, sh.s_name
HAVING COUNT(DISTINCT c.c_custkey) > 2
ORDER BY sales DESC, p.p_name, sh.s_name;
