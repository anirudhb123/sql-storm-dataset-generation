WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), 
avg_part_price AS (
    SELECT p.p_partkey, AVG(ps.ps_supplycost) AS avg_price
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT OUTER JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
ranked_orders AS (
    SELECT co.c_custkey, co.order_count, co.total_spent,
           DENSE_RANK() OVER (ORDER BY co.total_spent DESC) AS order_rank
    FROM customer_orders co
)
SELECT 
    n.n_name,
    COUNT(DISTINCT li.l_orderkey) AS orders_count,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank,
    sh.level AS supplier_level,
    pp.avg_price
FROM lineitem li
JOIN orders o ON li.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN supplier_hierarchy sh ON c.c_nationkey = sh.s_nationkey
JOIN avg_part_price pp ON li.l_partkey = pp.p_partkey
WHERE o.o_orderstatus = 'F' 
  AND li.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY n.n_name, sh.level, pp.avg_price
HAVING COUNT(DISTINCT li.l_orderkey) > 0 
   OR (SUM(li.l_extendedprice * (1 - li.l_discount)) IS NULL)
ORDER BY revenue_rank, n.n_name, supplier_level;
