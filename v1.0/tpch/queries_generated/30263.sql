WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s 
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
        WHERE s2.s_nationkey IS NOT NULL
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 3
),
PartSupply AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_availqty) > 100
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
RegionalSummary AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count, SUM(s.s_acctbal) AS total_acct_balance
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
)
SELECT 
    ph.p_name, 
    ph.total_avail_qty, 
    co.order_count, 
    SUM(COALESCE(od.revenue, 0)) AS total_revenue,
    s.s_name AS supplier_name,
    CASE 
        WHEN ph.total_avail_qty IS NULL THEN 'No Supply'
        ELSE 'Available'
    END AS supply_status,
    r.r_name AS region_name,
    r.nation_count
FROM PartSupply ph
JOIN CustomerOrders co ON ph.p_partkey = co.c_custkey
JOIN SupplierHierarchy s ON s.s_nationkey = co.order_count
JOIN RegionalSummary r ON r.nation_count = s.level
LEFT JOIN OrderDetails od ON od.o_orderkey = co.order_count
WHERE ph.total_avail_qty NOT BETWEEN 50 AND 150
GROUP BY ph.p_name, ph.total_avail_qty, co.order_count, s.s_name, r.r_name, r.nation_count
ORDER BY total_revenue DESC, ph.p_name ASC
LIMIT 10;
