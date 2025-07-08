
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 5
),
total_order_value AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY o.o_custkey
),
customer_stats AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(t.total_value) DESC) AS region_rank,
           SUM(t.total_value) AS total_spent
    FROM customer c
    LEFT JOIN total_order_value t ON c.c_custkey = t.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    px.ps_availqty,
    s.s_name AS supplier_name,
    COALESCE(cs.total_spent, 0) AS customer_spending,
    CASE 
        WHEN cs.region_rank IS NOT NULL THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM part p
LEFT JOIN partsupp px ON p.p_partkey = px.ps_partkey
LEFT JOIN supplier s ON px.ps_suppkey = s.s_suppkey
LEFT JOIN customer_stats cs ON s.s_nationkey = cs.c_nationkey
WHERE p.p_retailprice BETWEEN 100.00 AND 500.00
  AND (s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000)
ORDER BY customer_spending DESC, p.p_name;
