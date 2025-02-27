WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal * 0.9, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5 AND s.s_acctbal * 0.9 > 100
),
high_value_parts AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 50 AND p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) * 1.2
        FROM part p2
        WHERE p2.p_container LIKE '%BOX%'
    )
),
order_summaries AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_linenumber) AS item_count,
           RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag IS NULL
    GROUP BY o.o_orderkey
)
SELECT r.r_name, COUNT(DISTINCT wh.s_suppkey) AS total_suppliers, 
       AVG(o.total_revenue) AS avg_order_revenue, 
       SUM(CASE WHEN o.revenue_rank <= 10 THEN 1 ELSE 0 END) AS high_revenue_orders,
       COUNT(DISTINCT CASE WHEN p.ps_supplycost < 100 THEN p.p_partkey END) AS cheap_parts
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_hierarchy wh ON n.n_nationkey = wh.s_nationkey
LEFT JOIN high_value_parts p ON wh.s_suppkey = p.ps_supplycost
LEFT JOIN order_summaries o ON wh.s_suppkey = o.o_orderkey
WHERE r.r_comment IS NOT NULL AND (
    r.r_name LIKE 'S%' OR
    EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_nationkey = n.n_nationkey AND c.c_acctbal > 1000
    )
)
GROUP BY r.r_name
HAVING AVG(o.total_revenue) IS NOT NULL
ORDER BY COUNT(DISTINCT wh.s_suppkey) DESC, r.r_name;
