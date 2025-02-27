WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
TopSuppliers AS (
    SELECT s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp)
),
SalesByNation AS (
    SELECT n.n_name, COUNT(o.o_orderkey) AS order_count, AVG(o.o_totalprice) AS avg_order_value
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
)
SELECT rh.r_name, sbn.order_count, sbn.avg_order_value, ts.total_supply_cost
FROM region rh
FULL OUTER JOIN SalesByNation sbn ON rh.r_name = sbn.n_name
FULL OUTER JOIN TopSuppliers ts ON ts.s_name = 'SupplierA'
WHERE (sbn.order_count IS NOT NULL AND ts.total_supply_cost > 10000) OR (sbn.order_count IS NULL AND ts.total_supply_cost IS NULL)
ORDER BY sbn.order_count DESC NULLS LAST, ts.total_supply_cost DESC;
