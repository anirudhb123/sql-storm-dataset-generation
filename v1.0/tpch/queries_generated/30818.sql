WITH RECURSIVE supply_chain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    UNION ALL
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN supply_chain sc ON ps.ps_partkey = sc.ps_partkey
    WHERE ps.ps_availqty > sc.ps_availqty
), ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
), available_parts AS (
    SELECT p.p_partkey, p.p_name, COALESCE(SUM(ps.ps_availqty), 0) AS total_available
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), customer_summary AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_spent, 
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.o_orderkey, r.o_totalprice, r.o_orderdate, 
       p.p_name, 
       COALESCE(ap.total_available, 0) AS available_parts, 
       cs.c_name, cs.total_spent, cs.order_count
FROM ranked_orders r
JOIN lineitem l ON r.o_orderkey = l.l_orderkey
JOIN available_parts ap ON l.l_partkey = ap.p_partkey
LEFT JOIN customer_summary cs ON cs.total_spent > 1000
WHERE r.price_rank <= 10
ORDER BY r.o_orderdate DESC, r.o_totalprice DESC;
