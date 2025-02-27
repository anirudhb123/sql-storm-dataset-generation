WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_name = 'Customer A'
    )
    WHERE o.o_orderstatus = 'O' AND oh.level < 5
),
SupplierStats AS (
    SELECT s.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS part_count, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
RankedLineItems AS (
    SELECT l.*, 
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank,
           SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY l.l_orderkey) AS total_order_value
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
),
RegionSupplier AS (
    SELECT r.r_regionkey, r.r_name, s.s_name, ss.part_count, ss.total_supply_cost
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
)
SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice,
       COUNT(DISTINCT r.r_regionkey) AS region_count,
       SUM(ls.total_order_value) AS total_value,
       AVG(ss.total_supply_cost) AS avg_supply_cost
FROM OrderHierarchy oh
LEFT JOIN RankedLineItems ls ON oh.o_orderkey = ls.l_orderkey
LEFT JOIN RegionSupplier r ON r.s_name IS NULL
LEFT JOIN SupplierStats ss ON ls.l_suppkey = ss.s_suppkey
GROUP BY oh.o_orderkey, oh.o_orderdate, oh.o_totalprice
HAVING COUNT(oh.o_orderkey) > 0
ORDER BY oh.o_totalprice DESC 
LIMIT 10;
