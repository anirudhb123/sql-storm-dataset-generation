WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_custkey IN (SELECT s.s_nationkey FROM supplier s WHERE s.s_acctbal > 1000)
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_nationkey = ch.custkey
),
AggregatedSales AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
    GROUP BY l.l_orderkey
),
SupplierPerformance AS (
    SELECT s.s_suppkey, COUNT(ps.ps_partkey) AS part_count, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
SalesRanking AS (
    SELECT o.o_orderkey, ROW_NUMBER() OVER (PARTITION BY l.l_shipmode ORDER BY total_sales DESC) AS rank
    FROM AggregatedSales as s
    JOIN lineitem l ON s.l_orderkey = l.l_orderkey
)
SELECT r.r_name, 
       COALESCE(SUM(sp.total_supply_cost), 0) AS total_supplier_cost,
       COUNT(DISTINCT ch.c_custkey) AS active_customers,
       COUNT(DISTINCT sr.o_orderkey) AS total_orders,
       STRING_AGG(DISTINCT p.p_name || ' (' || p.p_size || ')', ', ') AS products
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
LEFT JOIN CustomerHierarchy ch ON n.n_nationkey = ch.c_nationkey
LEFT JOIN SalesRanking sr ON ch.c_custkey = sr.o_orderkey
LEFT JOIN part p ON sr.o_orderkey = p.p_partkey
WHERE r.r_name LIKE 'N%' OR r.r_comment IS NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT sr.o_orderkey) > 10
ORDER BY total_supplier_cost DESC;
