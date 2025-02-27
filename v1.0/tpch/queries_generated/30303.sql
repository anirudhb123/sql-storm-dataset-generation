WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS level
    FROM region
    WHERE r_regionkey = 1

    UNION ALL

    SELECT n.n_regionkey, r.r_name, r.r_comment, level + 1
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN region_hierarchy rh ON rh.r_regionkey = r.r_regionkey
),

top_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
),

supplier_part AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey, s.s_name
),

lineitem_analysis AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_shipdate DESC) AS rn
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)

SELECT rh.r_name, count(DISTINCT c.c_custkey) AS customer_count,
       SUM(l.revenue) AS total_revenue, 
       MAX(sp.total_supply_cost) AS max_supply_cost,
       COALESCE(NULLIF(greatest(sp.total_supply_cost, 0), 0), 'No Supplies') AS supply_status
FROM region_hierarchy rh
LEFT JOIN nation n ON rh.r_regionkey = n.n_regionkey
LEFT JOIN top_customers c ON c.c_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate > '2023-01-01'
)
LEFT JOIN lineitem_analysis l ON l.l_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
)
LEFT JOIN supplier_part sp ON sp.ps_partkey IN (
    SELECT l.l_partkey FROM lineitem l
)
GROUP BY rh.r_name;
