WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
high_value_lines AS (
    SELECT l_orderkey,
           SUM(l_extendedprice * (1 - l_discount)) AS total_value
    FROM lineitem
    GROUP BY l_orderkey
    HAVING SUM(l_extendedprice * (1 - l_discount)) > 
           (SELECT AVG(l_extendedprice * (1 - l_discount))
            FROM lineitem)
),
nations_with_high_value_orders AS (
    SELECT DISTINCT n.n_name
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN high_value_lines hv ON o.o_orderkey = hv.l_orderkey
),
part_analysis AS (
    SELECT p.p_partkey,
           p.p_name,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 1 AND AVG(ps.ps_supplycost) < 100
)
SELECT ph.p_partkey,
       ph.p_name,
       ph.supplier_count,
       ph.avg_supply_cost,
       nh.n_name
FROM part_analysis ph
JOIN nations_with_high_value_orders nh ON ph.supplier_count = 
    (SELECT MAX(pa.supplier_count)
     FROM part_analysis pa
     JOIN nations_with_high_value_orders nwo ON TRUE)
ORDER BY ph.avg_supply_cost DESC
LIMIT 10;
