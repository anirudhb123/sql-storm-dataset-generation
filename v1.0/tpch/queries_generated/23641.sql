WITH RECURSIVE nation_cte AS (
    SELECT n_nationkey, n_name, n_regionkey
    FROM nation
    WHERE n_name LIKE 'A%'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey
    FROM nation n
    JOIN nation_cte ncte ON n.n_regionkey = ncte.n_nationkey
),
supplier_summary AS (
    SELECT s.s_suppkey, COUNT(ps.ps_partkey) AS part_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           STRING_AGG(DISTINCT p.p_name, ', ') AS supplied_parts
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey
),
order_details AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate IS NOT NULL
    GROUP BY o.o_orderkey, o.o_custkey
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name,
           COALESCE(SUM(od.total_price), 0) AS total_order_value
    FROM customer c
    LEFT JOIN order_details od ON c.c_custkey = od.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 100
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, n.n_name, cs.c_name, cs.total_order_value,
       CASE 
           WHEN cs.total_order_value > 10000 THEN 'High Value'
           WHEN cs.total_order_value BETWEEN 5000 AND 10000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS order_value_category,
       s.part_count, s.total_supply_cost, s.supplied_parts
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN nation_cte ncte ON n.n_nationkey = ncte.n_nationkey
LEFT JOIN customer_order_summary cs ON cs.c_custkey IN (
    SELECT o.o_custkey
    FROM orders o
    WHERE o.o_orderstatus IN ('F', 'O') AND o.o_totalprice < 50000
)
LEFT JOIN supplier_summary s ON s.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_availqty IS NOT NULL AND ps.ps_availqty < (
        SELECT AVG(ps_availqty) FROM partsupp
    )
)
WHERE s.total_supply_cost IS NOT NULL
ORDER BY r.r_name, n.n_name, cs.total_order_value DESC
FETCH FIRST 50 ROWS ONLY;
