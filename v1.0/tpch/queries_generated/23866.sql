WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, 0 AS level
    FROM customer
    WHERE c_acctbal IS NOT NULL
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey 
    WHERE ch.level < 5
), 

PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           COALESCE(ps.ps_availqty, 0) AS available_quantity,
           COALESCE(ps.ps_supplycost, 0) AS supply_cost,
           p.p_size * 1.25 AS adjusted_size -- Unusual adjustment
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 50.00
), 

AggregatedOrderInfo AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(DISTINCT l.l_linenumber) AS line_count,
           COUNT(l.l_orderkey) OVER (PARTITION BY o.o_orderstatus) AS total_orders_status_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)

SELECT ch.c_name,
       p.p_name,
       pd.available_quantity,
       ROUND(pd.adjusted_size / NULLIF(pd.available_quantity, 0), 2) AS size_availability_ratio, -- Division by zero handled
       CASE 
           WHEN oi.net_revenue IS NULL THEN 'No orders'
           ELSE CAST(oi.net_revenue AS varchar(20))
       END AS net_revenue,
       CASE 
           WHEN EXISTS (SELECT 1 FROM region WHERE r_name LIKE 'N%' AND r_regionkey = n.n_regionkey) THEN 'Region N'
           ELSE 'Other Region'
       END AS region_classification
FROM CustomerHierarchy ch
CROSS JOIN nation n
JOIN PartDetails pd ON ch.c_nationkey = n.n_nationkey
LEFT JOIN AggregatedOrderInfo oi ON ch.c_custkey = oi.o_orderkey
WHERE n.n_comment LIKE '%important%' 
      AND pd.p_name NOT LIKE '%unused%'
ORDER BY ch.level, net_revenue DESC
LIMIT 50
UNION ALL 
SELECT 'Summary' AS c_name,
       NULL AS p_name,
       SUM(pd.available_quantity) AS available_quantity,
       ROUND(SUM(pd.adjusted_size) / NULLIF(SUM(pd.available_quantity), 0), 2) AS size_availability_ratio,
       NULL AS net_revenue,
       NULL AS region_classification
FROM PartDetails pd
WHERE pd.available_quantity < 100
GROUP BY pd.p_size
HAVING COUNT(*) > 1;
