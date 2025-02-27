WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s 
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
)
SELECT n.n_name AS nation_name, COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       AVG(co.total_spent) AS average_spent, MAX(co.order_count) AS max_orders
FROM nation n
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN customer_orders co ON co.c_custkey IN (
    SELECT DISTINCT o.o_custkey 
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
)
GROUP BY n.n_name
HAVING AVG(co.total_spent) IS NOT NULL AND MAX(co.order_count) > 10
ORDER BY supplier_count DESC, average_spent ASC;
