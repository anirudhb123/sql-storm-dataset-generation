WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_retailprice, p_comment
    FROM part
    WHERE p_size > 10
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_retailprice, CONCAT(ph.p_comment, ' -> ', p.p_comment)
    FROM part_hierarchy ph
    JOIN part p ON ph.p_partkey = p.p_partkey
    WHERE p.p_retailprice < ph.p_retailprice
), customer_orders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_custkey
), supplier_stats AS (
    SELECT s.s_suppkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey
)
SELECT ph.p_name,
       ph.p_retailprice,
       co.total_spent,
       co.order_count,
       s.avg_supplycost,
       CASE
           WHEN co.total_spent > 5000 THEN 'High'
           WHEN co.total_spent BETWEEN 1000 AND 5000 THEN 'Medium'
           ELSE 'Low'
       END AS customer_spending_category
FROM part_hierarchy ph
LEFT JOIN customer_orders co ON co.order_count > 5
JOIN supplier_stats s ON s.avg_supplycost < 100
WHERE ph.p_retailprice IS NOT NULL
ORDER BY ph.p_retailprice DESC, co.total_spent ASC;
