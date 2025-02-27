WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TotalLineItems AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_extended_price
    FROM lineitem
    WHERE l_returnflag = 'N'
    GROUP BY l_orderkey
),
CustomerOrderCounts AS (
    SELECT c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_custkey
),
AvgOrderPrices AS (
    SELECT o.o_orderkey, AVG(l.l_extendedprice) AS avg_price_per_order
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    c.c_name,
    c.c_acctbal,
    COALESCE(coc.order_count, 0) AS total_orders,
    th.total_extended_price,
    AVG(aop.avg_price_per_order) OVER (PARTITION BY c.c_nationkey) AS avg_price_by_nation,
    CASE WHEN s.level > 2 THEN 'High Tier' ELSE 'Standard Tier' END AS supplier_tier_status
FROM customer c
LEFT JOIN CustomerOrderCounts coc ON c.c_custkey = coc.c_custkey
LEFT JOIN TotalLineItems th ON th.l_orderkey IN (
    SELECT DISTINCT o.o_orderkey
    FROM orders o
    WHERE o.o_orderstatus = 'F'
)
LEFT JOIN SupplierHierarchy s ON s.s_nationkey = c.c_nationkey
LEFT JOIN AvgOrderPrices aop ON th.l_orderkey = aop.o_orderkey
WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
ORDER BY c.c_name, total_orders DESC NULLS LAST;
