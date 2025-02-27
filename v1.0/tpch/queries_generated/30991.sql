WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, level + 1
    FROM orders oh
    JOIN OrderHierarchy o ON oh.o_orderkey = o.o_orderkey
    WHERE oh.o_orderstatus = 'O'
),
SupplierStats AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerRegion AS (
    SELECT c.c_custkey,
           r.r_name AS region_name,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, r.r_name
),
RankedLineItems AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT cr.region_name,
       COUNT(DISTINCT cr.c_custkey) AS customer_count,
       AVG(ss.total_supply_cost) AS avg_supply_cost,
       SUM(rl.total_revenue) AS total_revenue,
       MAX(rl.total_revenue) AS max_single_order_revenue
FROM CustomerRegion cr
LEFT JOIN SupplierStats ss ON cr.c_custkey = ss.ps_partkey
JOIN RankedLineItems rl ON cr.c_custkey = rl.l_orderkey
WHERE cr.total_spent IS NOT NULL
AND cr.region_name IS NOT NULL
GROUP BY cr.region_name
HAVING COUNT(DISTINCT cr.c_custkey) > 10
ORDER BY total_revenue DESC;
