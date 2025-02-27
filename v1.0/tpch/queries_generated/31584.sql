WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, s2.s_acctbal, sh.level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s2.s_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, MAX(o.o_totalprice) AS max_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING MAX(o.o_totalprice) > 5000
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           COALESCE(s.s_acctbal, 0) AS supplier_acctbal
    FROM partsupp ps
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
SalesAnalysis AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           AVG(l.l_tax) AS average_tax,
           COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY l.l_orderkey
)
SELECT nh.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(CASE WHEN h.max_order_value > 10000 THEN 1 ELSE 0 END) AS high_value_customers,
       SUM(pa.ps_availqty) AS total_available_qty,
       (SELECT COUNT(*) FROM PartDetails pd WHERE pd.brand_rank <= 5) AS top_brands_count,
       AVG(sa.total_sales) AS avg_sales_value
FROM nation nh
LEFT JOIN customer c ON c.c_nationkey = nh.n_nationkey
LEFT JOIN HighValueCustomers h ON c.c_custkey = h.c_custkey
LEFT JOIN PartSupplierInfo pa ON pa.ps_partkey IN (SELECT p.p_partkey FROM PartDetails p)
LEFT JOIN SalesAnalysis sa ON sa.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
GROUP BY nh.n_name
HAVING SUM(pa.supplier_acctbal) IS NOT NULL
ORDER BY customer_count DESC;
