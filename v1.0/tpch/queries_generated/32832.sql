WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 AS level
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.r_regionkey, r.r_name, r.r_comment, rh.level + 1
    FROM region_hierarchy rh
    JOIN nation n ON rh.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE rh.level < 3
),
supply_summary AS (
    SELECT p.p_name, 
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS average_supply_cost,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_name
),
orders_with_discount AS (
    SELECT o.o_orderkey, 
           o.o_totalprice * (1 - l.l_discount) AS adjusted_total,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount > 0.1 OR l.l_discount IS NULL
),
final_summary AS (
    SELECT rh.r_name, 
           ss.p_name,
           ss.total_available,
           ss.average_supply_cost,
           ow.adjusted_total
    FROM region_hierarchy rh
    LEFT JOIN supply_summary ss ON rh.level = 0
    LEFT JOIN orders_with_discount ow ON ss.p_name = ow.o_orderkey
)
SELECT r_name, 
       p_name,
       total_available,
       average_supply_cost,
       adjusted_total,
       COALESCE(adjusted_total, 0) AS total_adjusted
FROM final_summary
WHERE total_available > 100
ORDER BY r_name, average_supply_cost DESC;
