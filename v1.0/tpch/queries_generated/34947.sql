WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size >= 10 AND ps.ps_availqty > 30
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           MAX(o.o_totalprice) AS max_order_price
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PriceAnalysis AS (
    SELECT pd.p_partkey, pd.p_name, pd.ps_supplycost,
           CASE WHEN pd.ps_supplycost IS NULL THEN 0 ELSE pd.ps_supplycost END AS adjusted_cost
    FROM PartSupplierDetails pd
    WHERE pd.rn = 1
),
Summary AS (
    SELECT c.c_name, co.total_orders, co.max_order_price,
           pa.adjusted_cost, ROW_NUMBER() OVER (ORDER BY total_orders DESC) AS order_rank
    FROM CustomerOrders co
    JOIN PriceAnalysis pa ON co.total_orders > 5
    JOIN region r ON co.total_orders = r.r_regionkey
)
SELECT sh.s_suppkey, sh.s_name, s.total_orders, s.max_order_price, s.adjusted_cost
FROM SupplierHierarchy sh
FULL OUTER JOIN Summary s ON sh.s_nationkey = s.c_name
WHERE s.adjusted_cost IS NOT NULL OR sh.s_acctbal IS NOT NULL
ORDER BY s.total_orders DESC, sh.level ASC;
