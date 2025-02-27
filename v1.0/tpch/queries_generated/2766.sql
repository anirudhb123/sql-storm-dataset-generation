WITH ranked_suppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), high_value_orders AS (
    SELECT o.o_orderkey,
           o.o_totalprice,
           o.o_orderdate,
           o.o_orderstatus,
           AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
), customer_order_summary AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_value,
           MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT co.c_custkey,
       co.c_name,
       co.total_orders,
       co.total_spent,
       co.avg_order_value,
       co.last_order_date,
       rs.s_name AS top_supplier
FROM customer_order_summary co
LEFT JOIN ranked_suppliers rs ON co.total_spent > 1000 AND rs.rank = 1
WHERE co.last_order_date IS NOT NULL
ORDER BY co.total_spent DESC
LIMIT 10;
