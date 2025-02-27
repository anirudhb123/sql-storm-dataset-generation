WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 1000
),
PartSales AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2022-01-01'
    GROUP BY p.p_partkey, p.p_name
),
HighValueSales AS (
    SELECT ps.p_partkey, ps.total_sales, RANK() OVER (ORDER BY ps.total_sales DESC) AS sales_rank
    FROM PartSales ps
    WHERE ps.total_sales > 50000
),
CustomerPurchases AS (
    SELECT c.c_custkey, c.c_name, COALESCE(SUM(l.l_extendedprice), 0) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
)
SELECT s.s_name, s.s_acctbal, p.p_name, COALESCE(hs.total_sales, 0) AS part_sales, 
       cp.total_spent, sh.level
FROM supplier s
FULL OUTER JOIN HighValueSales hs ON s.s_suppkey = hs.p_partkey
JOIN CustomerPurchases cp ON s.s_nationkey = cp.c_custkey
JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE s.s_acctbal >= 1500
AND (hs.total_sales IS NOT NULL OR cp.total_spent > 1000)
ORDER BY s.s_name, part_sales DESC
LIMIT 50;
