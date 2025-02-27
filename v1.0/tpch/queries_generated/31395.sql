WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_size, 0 AS level
    FROM part
    WHERE p_size >= 20
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_size, ph.level + 1
    FROM part_hierarchy ph
    JOIN partsupp ps ON ph.p_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ph.level < 5
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
supplier_stats AS (
    SELECT s.s_suppkey, s.s_name, AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
nation_details AS (
    SELECT n.n_nationkey, n.n_name,
           COALESCE(SUM(cs.total_spent), 0) AS total_spent_by_customers,
           COALESCE(SUM(ss.avg_supply_cost), 0) AS avg_supply_cost
    FROM nation n
    LEFT JOIN customer_summary cs ON n.n_nationkey = cs.c_custkey
    LEFT JOIN supplier_stats ss ON n.n_nationkey = ss.s_suppkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ph.p_name,
    ph.level,
    nd.n_name,
    nd.total_spent_by_customers,
    nd.avg_supply_cost
FROM part_hierarchy ph
JOIN lineitem l ON ph.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer_summary cs ON o.o_custkey = cs.c_custkey
JOIN nation_details nd ON cs.rank_within_nation = 1
WHERE l.l_discount > 0.1
  AND nd.total_spent_by_customers IS NOT NULL
ORDER BY ph.level, nd.total_spent_by_customers DESC;

