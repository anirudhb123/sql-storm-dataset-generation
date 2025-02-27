
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal * 0.9, h.level + 1
    FROM supplier s
    JOIN SupplierHierarchy h ON s.s_suppkey = h.s_suppkey
    WHERE h.level < 3
),
SalesData AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
    GROUP BY c.c_custkey, c.c_name
),
PartStock AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_stock
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.total_stock,
           RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    LEFT JOIN PartStock ps ON p.p_partkey = ps.p_partkey
),
CustomerAnalytics AS (
    SELECT c.c_custkey, c.c_name, sa.total_sales,
           COALESCE(ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY sa.total_sales DESC), 0) AS sales_rank
    FROM customer c
    LEFT JOIN SalesData sa ON c.c_custkey = sa.c_custkey
)
SELECT ch.level, ra.p_name, ca.c_name, ra.total_stock, ca.total_sales
FROM RankedParts ra
FULL OUTER JOIN CustomerAnalytics ca ON ra.p_partkey = ca.c_custkey
JOIN SupplierHierarchy ch ON ch.s_suppkey = ra.p_partkey
WHERE ra.total_stock > 10
AND (ca.total_sales IS NULL OR ca.total_sales > 1000)
ORDER BY ch.level, ra.price_rank, ca.sales_rank
FETCH FIRST 10 ROWS ONLY;
