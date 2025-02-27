WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
SupplierStats AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY s.s_suppkey, s.s_name
),
MaxLineItem AS (
    SELECT l.l_orderkey,
           MAX(l.l_extendedprice) AS max_price
    FROM lineitem l
    GROUP BY l.l_orderkey
),
RegionSummary AS (
    SELECT n.n_regionkey,
           r.r_name,
           COUNT(DISTINCT c.c_custkey) AS cust_count,
           SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_regionkey, r.r_name
),
FinalSummary AS (
    SELECT rh.o_orderkey, 
           rh.o_orderdate, 
           rh.o_totalprice, 
           ls.l_returnflag, 
           ls.l_linestatus, 
           rs.total_sales AS regional_sales,
           ss.total_avail_qty,
           ss.avg_supply_cost
    FROM OrderHierarchy rh
    LEFT JOIN lineitem ls ON rh.o_orderkey = ls.l_orderkey
    LEFT JOIN RegionSummary rs ON rs.cust_count > 0
    LEFT JOIN SupplierStats ss ON ss.total_avail_qty > 100
)
SELECT f.o_orderkey,
       f.o_orderdate,
       f.o_totalprice,
       f.regional_sales,
       COALESCE(f.total_avail_qty, 0) AS total_avail_qty,
       ROUND(f.avg_supply_cost, 2) AS avg_supply_cost
FROM FinalSummary f
WHERE f.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY f.o_orderdate DESC;
