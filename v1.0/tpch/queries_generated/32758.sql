WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_size, p_retailprice, 0 AS level
    FROM part
    WHERE p_size < 10
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice, ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON p.p_size = ph.p_size + 1
),
SupplierStats AS (
    SELECT s.s_nationkey, COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
           AVG(s.s_acctbal) AS avg_balance, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
FinalStats AS (
    SELECT r.r_name, ss.total_suppliers, ss.avg_balance, os.total_revenue
    FROM region r
    LEFT JOIN SupplierStats ss ON r.r_regionkey = ss.s_nationkey
    LEFT JOIN OrderStats os ON os.total_revenue IS NOT NULL
)
SELECT fh.p_name, fh.p_retailprice, fs.r_name, fs.total_suppliers, fs.avg_balance, 
       COALESCE(fs.total_revenue, 0) AS total_revenue,
       ROW_NUMBER() OVER (PARTITION BY fs.r_name ORDER BY fh.p_retailprice DESC) AS rank_within_region
FROM PartHierarchy fh
JOIN FinalStats fs ON fh.p_size = (SELECT MAX(p_size) FROM part WHERE p_size < fh.p_size)
WHERE fh.p_retailprice IS NOT NULL
ORDER BY fs.r_name, rank_within_region;
