WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 5
),
AggregatedSales AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_shipdate >= '2022-01-01'
    GROUP BY l.l_partkey
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_retailprice, a.total_sales
    FROM part p
    JOIN AggregatedSales a ON p.p_partkey = a.l_partkey
    WHERE a.total_sales > 10000
),
CustomerRank AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)
SELECT 
    t.p_partkey,
    t.p_name,
    t.p_brand,
    t.p_type,
    t.p_size,
    t.p_retailprice,
    COALESCE(c.customer_count, 0) AS customer_count,
    sh.level AS supplier_level
FROM TopParts t
LEFT JOIN (
    SELECT ps.ps_partkey, COUNT(DISTINCT s.s_suppkey) AS customer_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
) c ON t.p_partkey = c.ps_partkey
LEFT JOIN SupplierHierarchy sh ON t.p_partkey = sh.s_nationkey
WHERE (t.p_size >= 10 OR t.p_retailprice < 50.00) AND t.p_type LIKE '%metal%'
ORDER BY t.p_retailprice DESC, t.p_name
LIMIT 100;
