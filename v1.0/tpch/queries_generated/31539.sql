WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_availqty > 500)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
OrderValue AS (
    SELECT o.orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS num_suppliers, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    nh.n_nationkey,
    nh.n_name,
    NVL(os.total_order_value, 0) AS total_order_value,
    ns.total_supply_cost,
    sh.level,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(s.s_acctbal) FILTER (WHERE s.s_acctbal IS NOT NULL) AS avg_account_balance
FROM NationSummary ns
JOIN nation nh ON ns.n_nationkey = nh.n_nationkey
LEFT JOIN OrderValue os ON ns.n_nationkey = (SELECT n_nationkey FROM supplier WHERE s_suppkey = os.orderkey % (SELECT COUNT(*) FROM supplier))
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = nh.n_nationkey
LEFT JOIN supplier s ON nh.n_nationkey = s.s_nationkey
WHERE ns.num_suppliers > 1
GROUP BY nh.n_nationkey, nh.n_name, os.total_order_value, ns.total_supply_cost, sh.level
ORDER BY ns.total_supply_cost DESC, nh.n_name ASC;
