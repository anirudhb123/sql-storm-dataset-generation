WITH RECURSIVE customer_order_cte AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
),
supplier_part_cost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * p.p_retailprice) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
),
high_value_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
recent_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(MONTH, -6, CURRENT_DATE)
),
order_line_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT c.c_custkey, c.c_name, coalesce(ro.o_totalprice, 0) AS recent_order_total,
       coalesce(spc.total_cost, 0) AS total_part_cost,
       (CASE WHEN hs.s_suppkey IS NOT NULL THEN 'High Value' ELSE 'Regular' END) AS supplier_status,
       ols.net_revenue
FROM customer c
LEFT JOIN customer_order_cte co ON c.c_custkey = co.c_custkey AND co.order_rank = 1
LEFT JOIN recent_orders ro ON co.o_orderkey = ro.o_orderkey
LEFT JOIN supplier_part_cost spc ON (spc.ps_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM high_value_suppliers s)
)) 
OR spc.ps_partkey IS NULL)
LEFT JOIN order_line_summary ols ON ols.l_orderkey = co.o_orderkey
LEFT JOIN lineitem l ON l.l_orderkey = co.o_orderkey AND l.l_returnflag = 'R'
WHERE (c.c_custkey % 2 = 0 AND c.c_name LIKE 'A%') OR l.l_shipdate IS NULL
ORDER BY recent_order_total DESC, total_part_cost;
