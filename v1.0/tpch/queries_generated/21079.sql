WITH RECURSIVE supplier_chain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sc.level + 1
    FROM supplier_chain sc
    JOIN supplier s ON s.s_suppkey = sc.s_suppkey
    WHERE sc.level < 5
),
part_supplier_cte AS (
    SELECT p.p_partkey, p.p_name, ps.ps_suppkey, ps.ps_availqty, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    p.p_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_value,
    COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
    COUNT(DISTINCT cs.c_custkey) AS number_of_customers,
    STRING_AGG(DISTINCT s.s_name || ' (Level ' || ch.level || ')', ', ') AS suppliers_chain
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier_chain ch ON ch.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = ch.s_suppkey
LEFT JOIN part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN customer_order_summary cs ON cs.c_custkey = o.o_custkey
WHERE r.r_name IS NOT NULL
  AND (p.p_retailprice > 50 OR p.p_size < 10)
  AND (l.l_shipdate BETWEEN CURRENT_DATE - INTERVAL '1 year' AND CURRENT_DATE)
  AND (l.l_tax IS NULL OR l.l_tax < 0.05)
GROUP BY r.r_name, p.p_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY total_value DESC, number_of_orders DESC
LIMIT 10;
