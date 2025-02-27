WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, 1 AS level
    FROM region
    WHERE r_name = 'ASIA'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, rh.level + 1
    FROM nation n
    JOIN region_hierarchy rh ON n.n_regionkey = rh.r_regionkey
),
supplier_performance AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supply_cost, 
           AVG(ps.ps_availqty) AS avg_avail_qty,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
total_sold AS (
    SELECT l.l_suppkey, SUM(l.l_quantity) AS total_quantity_sold
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY l.l_suppkey
),
customer_details AS (
    SELECT c.c_custkey, c.c_name, cn.total_quantity_sold
    FROM customer c
    LEFT JOIN total_sold cn ON c.c_custkey = cn.l_suppkey
    WHERE c.c_acctbal > 
        (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = 'BUILDING')
)
SELECT rh.r_name, 
       sp.s_name AS supplier_name, 
       sp.total_supply_cost, 
       sp.avg_avail_qty, 
       COALESCE(cd.total_quantity_sold, 0) AS total_quantity_sold,
       CASE 
           WHEN sp.rank = 1 THEN 'Top Supplier'
           ELSE 'Regular Supplier'
       END AS supplier_status
FROM region_hierarchy rh
JOIN supplier_performance sp ON rh.r_regionkey = sp.s_nationkey
LEFT JOIN customer_details cd ON sp.s_suppkey = cd.c_custkey
WHERE sp.total_supply_cost > (SELECT AVG(total_supply_cost) FROM supplier_performance)
ORDER BY rh.level, sp.total_supply_cost DESC;
