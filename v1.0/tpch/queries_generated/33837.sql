WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 5000
    
    UNION ALL
    
    SELECT ps.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
top_customers AS (
    SELECT *
    FROM customer_orders
    WHERE rank <= 5
)
SELECT p.p_name, p.p_brand, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COALESCE(NULLIF(AVG(CASE WHEN s.s_acctbal IS NOT NULL THEN s.s_acctbal ELSE 0 END), 0), 'No Suppliers') AS avg_supplier_balance,
       nt.n_name AS nation_name,
       ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY total_revenue DESC) AS part_rank
FROM lineitem l
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation nt ON s.s_nationkey = nt.n_nationkey
JOIN top_customers tc ON tc.total_orders > 10
GROUP BY p.p_partkey, p.p_name, p.p_brand, nt.n_name
HAVING total_revenue > 10000
ORDER BY total_revenue DESC;
