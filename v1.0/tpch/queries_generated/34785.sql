WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment, 0 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_nationkey, c.c_name, 
           LAG(o.o_totalprice) OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate) AS prev_total
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '2021-01-01' 
),
AggregatedSales AS (
    SELECT c.c_nationkey, SUM(od.o_totalprice) AS total_sales, 
           SUM(od.o_totalprice - COALESCE(od.prev_total, 0)) AS incremental_sales
    FROM OrderDetails od
    JOIN customer c ON od.c_nationkey = c.c_nationkey
    GROUP BY c.c_nationkey
),
SupplierSummary AS (
    SELECT s.s_nationkey, COUNT(DISTINCT p.p_partkey) AS unique_parts, 
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_nationkey
)
SELECT r.r_name, SUM(as.total_sales) AS total_sales, 
       SUM(ss.unique_parts) AS total_unique_parts, 
       AVG(ss.avg_supplycost) AS avg_supply_cost
FROM region r
LEFT JOIN AggregatedSales as ON r.r_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = as.c_nationkey)
LEFT JOIN SupplierSummary ss ON ss.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
GROUP BY r.r_name
ORDER BY total_sales DESC, r.r_name ASC;
