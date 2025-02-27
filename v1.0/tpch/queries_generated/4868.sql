WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
BestPart AS (
    SELECT p.p_partkey, p.p_name, MAX(ps.ps_supplycost) AS max_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),

AggregatedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sale,
        COUNT(DISTINCT l.l_orderkey) AS total_lines,
        DATE_TRUNC('month', o.o_orderdate) AS order_month
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, DATE_TRUNC('month', o.o_orderdate)
)

SELECT 
    r.r_name,
    SUM(ao.total_sale) AS total_sales,
    AVG(sh.s_acctbal) AS avg_account_balance,
    COUNT(DISTINCT ao.o_orderkey) AS total_orders,
    MAX(bp.max_supply_cost) AS max_supply_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN AggregatedOrders ao ON s.s_nationkey = ao.o_orderkey
LEFT JOIN BestPart bp ON s.s_suppkey = bp.p_partkey
WHERE sh.level = (SELECT MAX(level) FROM SupplierHierarchy)
AND r.r_name IS NOT NULL
GROUP BY r.r_name
ORDER BY total_sales DESC
LIMIT 10;
