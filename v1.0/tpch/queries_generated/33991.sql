WITH RECURSIVE recent_orders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, o_orderstatus, 1 AS level
    FROM orders
    WHERE o_orderdate >= (CURRENT_DATE - INTERVAL '1 year')
    
    UNION ALL
    
    SELECT o.orderkey, o.custkey, o.orderdate, o.totalprice, o.orderstatus, r.level + 1
    FROM orders o
    JOIN recent_orders r ON o.custkey = r.o_custkey
    WHERE o.orderdate < r.o_orderdate
    AND r.level < 5
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COUNT(ps.ps_partkey) AS total_parts
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING COUNT(ps.ps_partkey) > 0
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           NTILE(10) OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_decile
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT DISTINCT
    p.p_name,
    p.p_brand,
    p.p_type,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT coalesce(o.o_orderkey, -1)) AS num_orders,
    MAX(s.s_acctbal) AS max_supplier_acctbal,
    c.c_name AS top_customer_name,
    d.spending_decile
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN supplier_details s ON s.s_suppkey = l.l_suppkey
LEFT JOIN top_customers c ON c.c_custkey = o.o_custkey
JOIN region r ON p.p_container IS NOT NULL
WHERE r.r_name LIKE '%East%'
AND p.p_retailprice > 50
AND EXISTS (
    SELECT 1
    FROM national n
    WHERE n.n_nationkey = s.s_nationkey
    AND n.n_name = 'USA'
)
GROUP BY p.p_name, p.p_brand, p.p_type, c.c_name, d.spending_decile
ORDER BY revenue DESC
LIMIT 10;
