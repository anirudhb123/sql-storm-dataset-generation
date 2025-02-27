WITH RECURSIVE supplier_chain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_availqty DESC) as availability_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS line_count,
           AVG(l.l_extendedprice) AS avg_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS orders_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT cs.c_name, cs.orders_count, cs.total_spent, os.total_revenue, os.line_count,
       CASE 
           WHEN cs.total_spent IS NULL THEN 'No Orders'
           WHEN cs.total_spent > os.total_revenue THEN 'Spent More'
           ELSE 'Spent Less'
       END AS spending_comparison,
       CASE 
           WHEN s.availability_rank = 1 THEN 'Top Supplier'
           ELSE 'Other Supplier'
       END AS supplier_status
FROM customer_summary cs
FULL OUTER JOIN order_summary os ON cs.orders_count = os.line_count
JOIN supplier_chain s ON s.ps_partkey = os.o_orderkey
WHERE cs.total_spent IS NOT NULL OR os.total_revenue IS NOT NULL
ORDER BY cs.total_spent DESC NULLS LAST, os.total_revenue DESC NULLS LAST;
