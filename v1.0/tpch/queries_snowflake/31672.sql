WITH RECURSIVE historical_orders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice
    FROM orders
    WHERE o_orderdate >= '1997-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    JOIN historical_orders ho ON o.o_orderkey = ho.o_orderkey
    WHERE o.o_orderdate < ho.o_orderdate
),
ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
distinct_part_combinations AS (
    SELECT DISTINCT p.p_partkey, p.p_name, p.p_brand, n.n_name AS nation
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE p.p_retailprice > 50.00 AND n.n_regionkey = 1
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT co.total_spent, ps.total_cost, dc.nation, COUNT(dc.p_partkey) AS part_count
FROM customer_order_summary co
FULL OUTER JOIN ranked_suppliers ps ON co.c_custkey = ps.s_suppkey
JOIN distinct_part_combinations dc ON ps.s_suppkey = dc.p_partkey
WHERE co.total_spent IS NOT NULL OR ps.total_cost IS NOT NULL
GROUP BY co.total_spent, ps.total_cost, dc.nation
HAVING AVG(COALESCE(co.total_spent, 0)) > 100 AND SUM(COALESCE(ps.total_cost, 0)) < 5000
ORDER BY dc.nation, part_count DESC;