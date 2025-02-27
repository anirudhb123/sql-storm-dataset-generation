WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.custkey = oh.o_custkey)
    WHERE oh.level < 5
),
SupplierStats AS (
    SELECT s.s_suppkey, 
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemStats AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS total_items,
           AVG(l.l_quantity) AS avg_quantity,
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.r_name AS region_name,
       COUNT(DISTINCT n.n_nationkey) AS nation_count,
       SUM(COALESCE(ss.total_supply_cost, 0)) AS total_supplier_cost,
       os.o_orderkey,
       os.o_orderdate,
       COALESCE(ls.total_revenue, 0) AS total_revenue,
       ls.avg_quantity,
       oh.level
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierStats ss ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l))
LEFT JOIN OrderHierarchy oh ON oh.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
LEFT JOIN LineItemStats ls ON ls.l_orderkey = oh.o_orderkey
GROUP BY r.r_name, os.o_orderkey, os.o_orderdate, ls.avg_quantity, oh.level
HAVING COUNT(n.n_nationkey) > 1 AND SUM(COALESCE(ss.total_supply_cost, 0)) > 1000
ORDER BY total_revenue DESC, region_name;
