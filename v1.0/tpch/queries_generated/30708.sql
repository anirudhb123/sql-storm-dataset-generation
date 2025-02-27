WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, level + 1
    FROM supplier s
    INNER JOIN SupplierCTE cte ON s.s_nationkey = cte.n_nationkey
    WHERE s.s_acctbal > cte.s_acctbal
),
TotalLineItems AS (
    SELECT l.l_orderkey, COUNT(l.l_linenumber) AS total_items
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
)
SELECT c.c_name, c.c_acctbal, r.r_name, COUNT(DISTINCT l.l_orderkey) AS order_count,
       MAX(t.total_items) AS max_items,
       AVG(sc.total_supply_cost) AS avg_supply_cost
FROM customer c
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN TotalLineItems t ON l.l_orderkey = t.l_orderkey
JOIN RankedOrders ro ON o.o_orderkey = ro.o_orderkey
JOIN SupplierCost sc ON l.l_partkey = sc.ps_partkey
WHERE r.r_name LIKE 'N%' 
  AND c.c_acctbal IS NOT NULL
  AND (c.c_name LIKE 'A%' OR c.c_name IS NULL)
GROUP BY c.c_name, c.c_acctbal, r.r_name
HAVING COUNT(DISTINCT l.l_orderkey) > 3
  AND AVG(sc.total_supply_cost) <= 100.00
ORDER BY c.c_acctbal DESC, order_count DESC;
