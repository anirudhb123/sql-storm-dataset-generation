WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_size, p_retailprice, 1 AS level
    FROM part
    WHERE p_size < 20
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice, ph.level + 1
    FROM part_hierarchy ph
    JOIN part p ON ph.p_partkey = p.p_partkey
    WHERE p.p_size < 30 AND ph.level < 5
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
customer_order_count AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_name,
    r.r_name AS region,
    n.n_name AS nation,
    s.s_name AS supplier_name,
    sc.order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM part_hierarchy p
JOIN lineitem l ON l.l_partkey = p.p_partkey
JOIN supplier s ON s.s_suppkey = l.l_suppkey
JOIN nation n ON n.n_nationkey = s.s_nationkey
JOIN region r ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer_order_count sc ON sc.order_count > 0
GROUP BY p.p_name, r.r_name, n.n_name, s.s_name, sc.order_count
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY region, revenue_rank;
