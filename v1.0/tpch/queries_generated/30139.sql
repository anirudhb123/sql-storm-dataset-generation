WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, 0 as level
    FROM supplier s
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.n_nationkey = sh.n_nationkey
    WHERE sh.level < 5
),
OrderStats AS (
    SELECT
        o.o_orderkey,
        COUNT(l.l_linenumber) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MAX(l.l_shipdate) AS last_shipdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
SupplierRevenue AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT l.l_orderkey) AS orders_count
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_suppkey
)
SELECT
    r.r_name,
    SUM(os.total_revenue) AS total_order_revenue,
    COALESCE(SUM(sr.total_supply_cost), 0) AS total_supply_cost,
    AVG(CASE WHEN sh.level > 0 THEN sh.s_acctbal END) AS avg_acctbal_hierarchy,
    COUNT(DISTINCT os.o_orderkey) AS total_orders
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN OrderStats os ON o.o_orderkey = os.o_orderkey
LEFT JOIN SupplierRevenue sr ON c.c_nationkey = sr.ps_suppkey
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.n_nationkey
WHERE r.r_name LIKE 'A%'
GROUP BY r.r_name
ORDER BY total_order_revenue DESC;
