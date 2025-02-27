WITH RECURSIVE top_suppliers AS (
    SELECT s_suppkey, s_name, SUM(ps_supplycost * ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s_suppkey, s_name
    ORDER BY total_supply_value DESC
    LIMIT 10
), order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS line_count, o.o_orderdate,
           RANK() OVER (PARTITION BY DATE_TRUNC('month', o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
), customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate,
           COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
), part_revenue AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS part_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT DISTINCT c.c_name, coalesce(TOTAL_CUSTOMER_ORDER.total_spent, 0) AS total_spent,
       COALESCE(tr.total_supply_value, 0) AS total_supply_value,
       pr.part_revenue
FROM customer_orders CO
FULL OUTER JOIN (
    SELECT c.c_custkey, SUM(co.total_spent) AS total_spent
    FROM customer c
    LEFT JOIN customer_orders co ON c.c_custkey = co.c_custkey
    GROUP BY c.c_custkey
) AS TOTAL_CUSTOMER_ORDER ON CO.c_custkey = TOTAL_CUSTOMER_ORDER.c_custkey
FULL OUTER JOIN top_suppliers tr ON tr.s_suppkey = CO.o_orderkey
LEFT JOIN part_revenue pr ON CO.o_orderkey = pr.p_partkey
WHERE COALESCE(pr.part_revenue, 0) > 50000
AND (coalesce(TOTAL_CUSTOMER_ORDER.total_spent, 0) < 1000 OR TOTAL_CUSTOMER_ORDER.total_spent IS NULL)
ORDER BY total_spent DESC, total_supply_value DESC;
