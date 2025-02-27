
WITH RECURSIVE CustomerSegments AS (
    SELECT c_custkey, c_name, c_acctbal, c_mktsegment,
           ROW_NUMBER() OVER (PARTITION BY c_mktsegment ORDER BY c_acctbal DESC) AS rn
    FROM customer
    WHERE c_acctbal IS NOT NULL
), HighValueOrders AS (
    SELECT o_orderkey, o_custkey, SUM(l_extendedprice * (1 - l_discount)) AS total_order_value
    FROM orders
    JOIN lineitem ON orders.o_orderkey = lineitem.l_orderkey
    GROUP BY o_orderkey, o_custkey
    HAVING SUM(l_extendedprice * (1 - l_discount)) > (
        SELECT AVG(total_order_value)
        FROM (
            SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_order_value
            FROM lineitem
            GROUP BY l_orderkey
        ) AS avg_values
    )
), NationalSummary AS (
    SELECT n.n_nationkey, 
           n.n_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
), RankedNations AS (
    SELECT n.n_nationkey, 
           n.n_name,
           supplier_count, 
           total_supply_cost,
           RANK() OVER (ORDER BY total_supply_cost DESC) AS nation_rank
    FROM NationalSummary n
)
SELECT c.c_name, c.c_acctbal, r.n_name AS top_nation, 
       COALESCE(o.o_orderkey::text, 'No Orders') AS order_ref,
       (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = o.o_orderkey AND l.l_discount BETWEEN 0.05 AND 0.15) AS discount_items_count,
       CASE 
           WHEN c.c_acctbal IS NULL THEN 'Unknown'
           WHEN c.c_acctbal > 1000 THEN 'High Roller'
           ELSE 'Regular User' 
       END AS customer_type
FROM CustomerSegments c
LEFT JOIN HighValueOrders o ON c.c_custkey = o.o_custkey
JOIN RankedNations r ON c.c_mktsegment = 'BUILDING'
WHERE r.nation_rank <= 5
  AND (c.c_acctbal IS NOT NULL OR r.total_supply_cost IS NULL)
ORDER BY c.c_name, o.total_order_value DESC
LIMIT 50;
