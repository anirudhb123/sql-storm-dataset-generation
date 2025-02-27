WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (sh.level * 1000)
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_mktsegment,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' 
          AND o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_mktsegment
),
AveragePrice AS (
    SELECT c.c_nationkey, AVG(od.total_line_price) AS avg_line_price
    FROM OrderDetails od
    JOIN customer c ON od.o_orderkey = c.c_custkey
    GROUP BY c.c_nationkey
),
SupplierStatistics AS (
    SELECT sh.s_nationkey, COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
           COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM SupplierHierarchy sh
    LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    GROUP BY sh.s_nationkey
)
SELECT r.r_name, 
       COALESCE(ss.supplier_count, 0) AS supplier_count,
       COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
       COALESCE(ap.avg_line_price, 0) AS avg_order_value
FROM region r
LEFT JOIN SupplierStatistics ss ON r.r_regionkey = ss.s_nationkey
LEFT JOIN AveragePrice ap ON r.r_regionkey = ap.c_nationkey
WHERE r.r_comment IS NOT NULL
ORDER BY r.r_name;
