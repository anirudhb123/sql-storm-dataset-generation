WITH RECURSIVE NationHierarchy AS (
    SELECT n.n_nationkey AS nation_key, n.n_name, r.r_name AS region_name, 0 AS level
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name = 'ASIA'
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, r.r_name, nh.level + 1
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN NationHierarchy nh ON nh.nation_key = n.n_nationkey
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_availability,
           SUM(ps.ps_supplycost) AS total_supply_cost, 
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rnk
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemAnalysis AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(DISTINCT l.l_partkey) AS distinct_parts,
           l.l_shipmode
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_shipmode
)
SELECT nh.n_name, nh.region_name, ss.s_name, ss.total_availability, ss.total_supply_cost,
       cos.total_spent, cos.order_count, la.revenue, la.distinct_parts
FROM NationHierarchy nh
LEFT JOIN SupplierStats ss ON nh.nation_key = ss.s_suppkey
FULL OUTER JOIN CustomerOrderStats cos ON ss.s_suppkey = cos.c_custkey
LEFT JOIN LineItemAnalysis la ON cos.c_custkey = la.l_orderkey
WHERE (ss.total_supply_cost IS NOT NULL OR cos.total_spent IS NULL)
  AND (la.revenue > 10000 OR nh.level > 1)
ORDER BY nh.n_name, ss.total_availability DESC, cos.total_spent ASC;
