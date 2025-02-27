WITH RECURSIVE NationCTE AS (
    SELECT n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_name LIKE 'A%'
    UNION ALL
    SELECT n.n_name, n.n_regionkey, cte.level + 1
    FROM nation n
    JOIN NationCTE cte ON n.n_regionkey = cte.n_regionkey
    WHERE n.n_name <> cte.n_name AND n.n_name LIKE 'A%'
),
PartSupplierCTE AS (
    SELECT ps.partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_name IS NOT NULL
    GROUP BY ps.partkey
),
AggregatedOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_discount) IS NOT NULL
),
RankedParts AS (
    SELECT p.p_partkey, RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
    AND p.p_size BETWEEN 10 AND 20
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    LEFT JOIN orders o ON o.o_custkey = s.s_nationkey
    WHERE o.o_orderstatus IN ('O', 'F') OR o.o_orderstatus IS NULL
),
FinalSelection AS (
    SELECT n.n_name, SUM(a.net_revenue) AS total_revenue, COUNT(DISTINCT ps.partkey) AS part_count
    FROM NationCTE n
    LEFT JOIN AggregatedOrders a ON n.n_regionkey = a.o_orderkey
    LEFT JOIN PartSupplierCTE ps ON a.o_orderkey = ps.partkey
    JOIN RankedParts rp ON ps.partkey = rp.p_partkey AND rp.rank <= 5
    GROUP BY n.n_name
    HAVING SUM(a.net_revenue) > 1000000 AND COUNT(ps.partkey) IS NOT NULL
)
SELECT n.n_name, f.total_revenue, f.part_count
FROM FinalSelection f
JOIN nation n ON f.total_revenue > (SELECT AVG(total_revenue) FROM FinalSelection)
ORDER BY f.total_revenue DESC, n.n_name ASC
LIMIT 10
OFFSET (SELECT COUNT(*) FROM FinalSelection) / 2

