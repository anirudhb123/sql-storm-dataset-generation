WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, h.s_nationkey, h.level + 1
    FROM supplier s
    JOIN SupplierHierarchy h ON s.s_suppkey = h.s_nationkey
    WHERE h.level < 5
),
TotalLineItems AS (
    SELECT l_orderkey, SUM(l_quantity) AS total_quantity
    FROM lineitem
    GROUP BY l_orderkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_totalprice > 1000
),
QualifiedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_brand,
           CASE 
               WHEN p.p_size > 10 THEN 'Large'
               WHEN p.p_size BETWEEN 5 AND 10 THEN 'Medium'
               ELSE 'Small'
           END AS size_category
    FROM part p
    WHERE p.p_retailprice BETWEEN 50 AND 200 AND p.p_container IS NOT NULL
),
NationOrderCount AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus NOT IN ('F', NULL)
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    s.s_name,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    nh.order_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
FROM lineitem l
JOIN OrderDetails od ON l.l_orderkey = od.o_orderkey
JOIN QualifiedParts p ON l.l_partkey = p.p_partkey
JOIN NationOrderCount nh ON nh.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = l.l_suppkey)
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = l.l_suppkey
WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY s.s_name, p.p_name, nh.order_count
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000 AND (COUNT(DISTINCT l.l_orderkey) > 5 OR SUM(l.l_discount) IS NULL)
ORDER BY sales_rank, total_sales DESC
LIMIT 10;
