WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 500.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TopCustomers AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
    GROUP BY c.c_custkey
    HAVING COUNT(o.o_orderkey) > 2
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(*) FILTER (WHERE l.l_returnflag = 'R') AS return_count,
           COUNT(*) FILTER (WHERE l.l_linestatus = 'O') AS open_line_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
RegionMetrics AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(CASE WHEN s.s_acctbal > 1000.00 THEN 1 ELSE 0 END) AS high_balance_suppliers
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
)
SELECT rh.level,
       rc.r_name,
       AVG(ts.total_spent) AS avg_spent,
       SUM(lis.net_revenue) AS total_net_revenue,
       (SELECT COUNT(*) FROM LineItemSummary) AS total_orders,
       MAX(rm.nation_count) OVER (PARTITION BY rm.r_name) AS max_nations,
       COUNT(DISTINCT rh.s_nationkey) AS supplier_nations
FROM SupplierHierarchy rh
JOIN TopCustomers ts ON rh.s_nationkey = ts.c_custkey
JOIN RegionMetrics rm ON rm.r_name = (
    SELECT n.n_name
    FROM nation n 
    WHERE n.n_nationkey = rh.s_nationkey
    LIMIT 1
)
LEFT JOIN LineItemSummary lis ON ts.c_custkey = lis.l_orderkey
WHERE rh.s_nationkey IS NOT NULL
GROUP BY rh.level, rc.r_name
ORDER BY 1 DESC, 2 ASC
LIMIT 10 OFFSET 3;
