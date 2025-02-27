WITH supplier_summary AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_availqty) AS total_available,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT o.o_orderkey,
           o.o_custkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
high_value_customers AS (
    SELECT c.c_custkey,
           c.c_name,
           c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
)
SELECT hvc.c_custkey,
       hvc.c_name,
       hvc.c_acctbal,
       os.total_revenue,
       ss.total_available,
       ss.total_supplycost,
       COALESCE(r.r_name, 'Unknown') AS region_name
FROM high_value_customers hvc
LEFT JOIN order_summary os ON hvc.c_custkey = os.o_custkey
LEFT JOIN supplier_summary ss ON os.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey IN (
        SELECT p.p_partkey
        FROM part p
        WHERE p.p_size >= 10
    )
)
LEFT JOIN nation n ON hvc.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE hvc.c_acctbal IS NOT NULL
ORDER BY hvc.c_acctbal DESC, os.total_revenue DESC
LIMIT 100;
