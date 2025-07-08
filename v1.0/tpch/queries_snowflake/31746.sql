WITH RECURSIVE nf AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment, 1 AS level
    FROM nation
    WHERE n_nationkey IS NOT NULL

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment, nf.level + 1
    FROM nation n
    JOIN nf ON n.n_regionkey = nf.n_nationkey
    WHERE nf.level < 3
),
agg_supplier AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available_quantity,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 100.00
    GROUP BY s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey, o.o_custkey
),
filtered_orders AS (
    SELECT os.o_orderkey, os.o_custkey, os.total_price, ROW_NUMBER() OVER(PARTITION BY os.o_custkey ORDER BY os.total_price DESC) as rn
    FROM order_summary os
),
customer_with_orders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, fo.total_price
    FROM customer c
    LEFT JOIN filtered_orders fo ON c.c_custkey = fo.o_custkey
    WHERE c.c_mktsegment = 'BUILDING' OR c.c_acctbal IS NULL
),
final_report AS (
    SELECT cw.c_custkey, cw.c_name, COALESCE(cw.total_price, 0) AS total_price,
           CASE 
               WHEN cw.total_price > 1000 THEN 'High Value'
               WHEN cw.total_price BETWEEN 500 AND 1000 THEN 'Mid Value'
               ELSE 'Low Value'
           END AS customer_value_group,
           (SELECT COUNT(*) FROM orders o WHERE o.o_custkey = cw.c_custkey) AS total_orders,
           n.n_name AS nation_name
    FROM customer_with_orders cw
    LEFT JOIN nation n ON cw.c_custkey = n.n_nationkey
)
SELECT f.*, RANK() OVER (ORDER BY f.total_price DESC) AS price_rank
FROM final_report f
WHERE f.customer_value_group = 'High Value' OR f.total_orders = 0
ORDER BY f.total_price DESC;