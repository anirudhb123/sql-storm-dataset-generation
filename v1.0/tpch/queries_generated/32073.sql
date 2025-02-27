WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS hierarchy_level
    FROM nation
    WHERE n_regionkey IS NOT NULL

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.hierarchy_level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
CustomerRanked AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank_within_nation
    FROM customer c
),
AveragePrice AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
LineItemStats AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT n.n_name AS nation_name,
       SUM(COALESCE(ls.total_revenue, 0)) AS total_revenue_in_nation,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       AVG(ap.avg_supplycost) AS average_supply_cost
FROM nation n
LEFT OUTER JOIN NationHierarchy nh ON nh.n_regionkey = n.n_nationkey
LEFT OUTER JOIN customer c ON c.c_nationkey = nh.n_nationkey
LEFT OUTER JOIN LineItemStats ls ON ls.l_orderkey IN (SELECT o.o_orderkey
                                                       FROM orders o
                                                       WHERE o.o_custkey = c.c_custkey)
LEFT OUTER JOIN AveragePrice ap ON ap.ps_partkey IN (SELECT ps.ps_partkey
                                                      FROM partsupp ps
                                                      WHERE ps.ps_suppkey IN (SELECT ts.s_suppkey
                                                                               FROM TopSuppliers ts))
WHERE nh.hierarchy_level > 0
GROUP BY n.n_name
HAVING SUM(COALESCE(ls.total_revenue, 0)) > 0
ORDER BY total_revenue_in_nation DESC;
