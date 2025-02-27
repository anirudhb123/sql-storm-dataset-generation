WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS hierarchy_level
    FROM nation
    WHERE n_regionkey = (SELECT MAX(r_regionkey) FROM region)

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.hierarchy_level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
AveragePrice AS (
    SELECT ps_partkey, AVG(ps_supplycost) AS avg_supplycost
    FROM partsupp
    GROUP BY ps_partkey
),
OrderedStats AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_order_value,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM orders o
    GROUP BY o.o_custkey
),
SupplierAvailability AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty IS NOT NULL
    GROUP BY s.s_suppkey
)
SELECT 
    nh.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.total_order_value) AS total_order_value,
    sa.total_avail_qty AS total_supply,
    CASE 
        WHEN AVG(ap.avg_supplycost) IS NULL THEN 'No Data'
        ELSE CONCAT('Avg Cost: $', ROUND(AVG(ap.avg_supplycost), 2))
    END AS average_supply_cost,
    RANK() OVER (ORDER BY SUM(o.total_order_value) DESC) AS sales_rank
FROM NationHierarchy nh
JOIN customer c ON c.c_nationkey = nh.n_nationkey
LEFT JOIN OrderedStats o ON o.o_custkey = c.c_custkey
LEFT JOIN SupplierAvailability sa ON sa.s_suppkey = (SELECT MIN(ps.ps_suppkey) FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size >= 30))
LEFT JOIN AveragePrice ap ON ap.ps_partkey = (SELECT MAX(ps_partkey) FROM partsupp)
GROUP BY nh.n_name, sa.total_avail_qty
HAVING SUM(o.total_order_value) > 1000
ORDER BY sales_rank;
