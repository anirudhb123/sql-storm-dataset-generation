WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 
           c.c_name AS customer_name, c.c_nationkey,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'F'
    UNION ALL
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, oh.o_orderstatus, 
           ch.c_name AS customer_name, ch.c_nationkey,
           ROW_NUMBER() OVER (PARTITION BY oh.o_orderkey ORDER BY oh.o_orderdate DESC) AS rn
    FROM OrderHierarchy oh
    JOIN customer ch ON oh.o_orderkey = ch.c_custkey
    WHERE oh.o_orderkey IS NOT NULL
),
SupplierPerformance AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * l.l_quantity) AS total_cost,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_returnflag = 'N' 
    GROUP BY ps.ps_suppkey
),
RegionalSummary AS (
    SELECT r.r_regionkey, r.r_name, 
           SUM(CASE WHEN c.c_mktsegment = 'BUILDING' THEN o.o_totalprice ELSE 0 END) AS building_sales,
           SUM(CASE WHEN c.c_mktsegment = 'FURNITURE' THEN o.o_totalprice ELSE 0 END) AS furniture_sales,
           NULLIF(SUM(o.o_totalprice), 0) AS total_sales
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT rh.customer_name, rh.o_orderkey, rh.o_orderdate, 
       COALESCE(rm.building_sales, 0) AS building_sales, 
       COALESCE(rm.furniture_sales, 0) AS furniture_sales,
       sp.order_count AS supplier_order_count,
       (sp.total_cost / NULLIF(sp.order_count, 0)) AS avg_cost_per_order,
       CASE 
           WHEN sp.total_cost > (SELECT AVG(total_cost) FROM SupplierPerformance) THEN 'Above Average'
           ELSE 'Below Average'
       END AS supplier_performance
FROM OrderHierarchy rh
JOIN RegionalSummary rm ON rh.n_nationkey = rm.r_regionkey
LEFT JOIN SupplierPerformance sp ON rh.o_orderkey = sp.ps_suppkey
ORDER BY rh.o_orderdate DESC, building_sales DESC;
