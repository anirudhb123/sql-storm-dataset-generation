WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey,
           CAST(s.s_name AS varchar(100)) AS full_name
    FROM supplier s
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey,
           CAST(CONCAT(sh.full_name, ' > ', s.s_name) AS varchar(100))
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE sh.s_acctbal < 5000
),
order_summary AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           SUM(CASE WHEN l.l_discount IS NULL THEN 0 ELSE l.l_discount END) AS total_discount,
           COUNT(DISTINCT l.l_partkey) AS total_items
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
customer_region AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, r.r_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name IS NOT NULL
),
part_supplier AS (
    SELECT p.p_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT cr.c_name, 
       s.full_name, 
       os.o_totalprice * (1 - os.total_discount / NULLIF(os.o_totalprice, 0)) AS net_price,
       ps.supplier_count,
       CASE 
           WHEN ps.avg_supply_cost > 100 THEN 'High Cost'
           WHEN ps.avg_supply_cost BETWEEN 50 AND 100 THEN 'Moderate Cost'
           ELSE 'Low Cost'
       END AS cost_category
FROM customer_region cr
LEFT JOIN order_summary os ON cr.c_custkey = os.o_orderkey
LEFT JOIN supplier_hierarchy s ON cr.c_nationkey = s.n_nationkey
LEFT JOIN part_supplier ps ON ps.p_partkey = os.o_orderkey
WHERE CRITICAL_STRING_EXPRESSION(cr.c_name, 'Critical') IS NOT NULL
  AND (ps.supplier_count > 1 OR os.total_items > 5)
ORDER BY net_price DESC, cr.c_name NULLS LAST;
