WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
RegionSummary AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
SupplierStats AS (
    SELECT ps.ps_supkey, SUM(ps.ps_supplycost) AS total_supplycost,
           AVG(s.s_acctbal) AS average_acctbal, 
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY ps.ps_suppkey
)
SELECT r.r_name as region, nh.n_name as nation, 
       SUM(os.total_sales) AS total_sales,
       AVG(ss.average_acctbal) AS avg_supplier_acctbal,
       MAX(ss.total_supplycost) AS max_supply_cost,
       CASE 
           WHEN AVG(ss.average_acctbal) IS NULL THEN 'No Data'
           ELSE 'Data Available'
       END AS acctbal_status
FROM RegionSummary r
JOIN NationHierarchy nh ON r.nation_count > 0
LEFT JOIN OrderSummary os ON nh.n_nationkey = os.o_custkey
LEFT JOIN SupplierStats ss ON ss.ps_supkey = nh.n_nationkey
WHERE r.nation_count > 5
GROUP BY r.r_name, nh.n_name
HAVING total_sales > (SELECT AVG(total_sales) FROM OrderSummary)
ORDER BY total_sales DESC;
