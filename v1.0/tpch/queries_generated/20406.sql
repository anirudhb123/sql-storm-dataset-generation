WITH RECURSIVE order_hierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 
           1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    UNION ALL
    SELECT o.orderkey, o.custkey, o.orderdate, o.totalprice, 
           oh.level + 1
    FROM orders o
    JOIN order_hierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_totalprice > oh.o_totalprice
),
supplier_part_cost AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_supplycost * l.l_quantity) AS total_cost
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
part_stats AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_supplier_acctbal,
           MAX(ps.ps_supplycost) AS max_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_size BETWEEN 10 AND 20
      AND p.p_retailprice IS NOT NULL
    GROUP BY p.p_partkey, p.p_name
),
high_cost_parts AS (
    SELECT p.p_partkey, p.p_name, h.total_cost
    FROM supplier_part_cost h
    JOIN part_stats p ON h.ps_partkey = p.p_partkey
    WHERE h.total_cost > (
        SELECT AVG(total_cost) 
        FROM supplier_part_cost
    )
    AND p.supplier_count > 2
),
final_selection AS (
    SELECT oh.o_orderkey, oh.o_orderdate, h.total_cost, 
           (h.total_cost - COALESCE(NULLIF(p.avg_supplier_acctbal, 0), 1)) AS adjusted_cost
    FROM order_hierarchy oh
    JOIN high_cost_parts h ON oh.o_orderkey = h.p_partkey
    LEFT JOIN part_stats p ON p.p_partkey = h.p_partkey
)
SELECT f.o_orderkey, f.o_orderdate, f.total_cost, 
       CASE 
           WHEN f.adjusted_cost > 1000 THEN 'High Cost'
           WHEN f.adjusted_cost BETWEEN 500 AND 1000 THEN 'Medium Cost'
           ELSE 'Low Cost'
       END AS cost_category,
       RANK() OVER (PARTITION BY f.o_orderdate ORDER BY f.total_cost DESC) AS rank
FROM final_selection f
WHERE f.o_orderdate >= CURRENT_DATE - INTERVAL '1 YEAR'
ORDER BY f.o_orderdate, rank;
