WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
AggregatePart AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
NationRegion AS (
    SELECT n.n_nationkey, r.r_regionkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name LIKE 'A%'
),
OrderDetails AS (
    SELECT o.o_orderkey, COUNT(l.l_orderkey) AS line_count, SUM(l.l_extendedprice) AS total_extended_price
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT
    p.p_name,
    sh.s_name,
    np.n_name AS nation_name,
    COALESCE(od.line_count, 0) AS order_line_count,
    od.total_extended_price,
    ap.total_avail_qty,
    ap.avg_supply_cost
FROM part p
JOIN AggregatePart ap ON p.p_partkey = ap.ps_partkey
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
JOIN NationRegion nr ON sh.s_nationkey = nr.n_nationkey
LEFT JOIN OrderDetails od ON od.o_orderkey = ps.ps_partkey
JOIN nation np ON sh.s_nationkey = np.n_nationkey
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice)
    FROM part p2
    WHERE p2.p_container IS NOT NULL
) AND sh.level > 0
ORDER BY total_extended_price DESC
LIMIT 100;
