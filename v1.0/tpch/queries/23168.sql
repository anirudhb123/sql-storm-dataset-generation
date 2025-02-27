
WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_size, p_retailprice, 1 AS depth
    FROM part
    WHERE p_size IS NOT NULL
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_size, (ph.p_retailprice * 0.95) AS p_retailprice, ph.depth + 1
    FROM part_hierarchy ph
    JOIN part p ON p.p_partkey = ph.p_partkey - 1
    WHERE ph.depth < 5
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
total_sales AS (
    SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           DATE_TRUNC('month', o.o_orderdate) AS month
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY DATE_TRUNC('month', o.o_orderdate)
),
customer_rank AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS seg_rank
    FROM customer c
)
SELECT 
    n.n_name,
    SUM(COALESCE(ps.ps_supplycost, 0) * ph.depth) AS total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS avg_order_price,
    STRING_AGG(DISTINCT ph.p_name, ', ') AS parts_details
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN part_hierarchy ph ON ph.p_partkey = ps.ps_partkey
LEFT JOIN ranked_orders o ON o.o_orderkey IN (
    SELECT o_sub.o_orderkey
    FROM ranked_orders o_sub
    WHERE o_sub.price_rank <= 10
)
LEFT JOIN total_sales ts ON ts.month = DATE_TRUNC('month', o.o_orderdate)
WHERE r.r_name LIKE 'N%'
AND (s.s_acctbal > 0 OR s.s_acctbal IS NULL)
GROUP BY n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_supply_cost DESC NULLS LAST;
