WITH top_products AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY p.p_partkey, p.p_name
    ORDER BY total_revenue DESC
    LIMIT 10
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
)

SELECT tp.p_name, sd.s_name AS supplier_name, cd.c_name AS customer_name, cd.order_count, cd.total_spent, tp.total_revenue
FROM top_products tp
JOIN supplier_details sd ON tp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
JOIN customer_orders cd ON cd.total_spent > 10000
ORDER BY total_revenue DESC, customer_name;