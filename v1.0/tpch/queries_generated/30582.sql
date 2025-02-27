WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), 

part_summary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty, 
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), 

lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY l.l_orderkey
), 

customer_exceeding_avg AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
)

SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.total_avail_qty,
    ps.total_supply_cost,
    COALESCE(ls.total_revenue, 0) AS total_revenue,
    ch.c_custkey,
    ch.c_name,
    sh.level
FROM part_summary ps
FULL OUTER JOIN lineitem_summary ls ON ps.p_partkey = ls.l_orderkey
JOIN customer_exceeding_avg ch ON ls.l_orderkey = ch.c_custkey
JOIN supplier_hierarchy sh ON ch.c_nationkey = sh.s_nationkey
WHERE ps.total_avail_qty > 100
  AND (ps.total_supply_cost IS NOT NULL OR ch.c_acctbal IS NOT NULL)
ORDER BY ps.total_supply_cost DESC, total_revenue DESC
LIMIT 100;
