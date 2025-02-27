WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND sh.level < 5
),
OrderDetails AS (
    SELECT o.o_orderkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_shipdate IS NOT NULL
    GROUP BY o.o_orderkey, c.c_name
),
SupplierStats AS (
    SELECT sh.s_name, COUNT(DISTINCT ps.ps_partkey) AS parts_supplied, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    GROUP BY sh.s_name
),
RankedOrders AS (
    SELECT od.*, 
           RANK() OVER (PARTITION BY od.c_name ORDER BY od.total_sales DESC) as rnk
    FROM OrderDetails od
),
FilteredOrders AS (
    SELECT *
    FROM RankedOrders
    WHERE rnk <= 10
)
SELECT s.s_name, COALESCE(stat.parts_supplied, 0) AS parts_supplied, 
       COALESCE(stat.avg_supply_cost, 0.00) AS avg_supply_cost,
       fo.total_sales
FROM SupplierStats stat
FULL OUTER JOIN FilteredOrders fo ON fo.c_name = (
    SELECT TOP 1 c.c_name
    FROM customer c
    WHERE c.c_nationkey = (
        SELECT COUNT(*) FROM nation n WHERE n.n_regionkey = 5
    )
    ORDER BY NEWID()
)
LEFT JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = 'FRANCE')
WHERE r.r_name IS NOT NULL OR r.r_comment IS NOT NULL
ORDER BY s.s_name, total_sales DESC;
