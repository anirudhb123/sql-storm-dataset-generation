WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 3
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
top_customers AS (
    SELECT *, RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM customer_orders
)
SELECT 
    r.r_name,
    n.n_name,
    SUM(ps.ps_supplycost * li.l_quantity) AS total_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
    AVG(COALESCE(c.c_acctbal, 0)) AS avg_customer_balance
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN lineitem li ON ps.ps_partkey = li.l_partkey
LEFT JOIN orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN top_customers c ON o.o_custkey = c.c_custkey
WHERE li.l_shipdate > CURRENT_DATE - INTERVAL '1 year'
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_cost DESC
LIMIT 10;
