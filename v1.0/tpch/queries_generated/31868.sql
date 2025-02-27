WITH RECURSIVE customer_hierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, 0 AS level
    FROM customer
    WHERE c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON ch.c_custkey = c.c_nationkey
),
total_order_value AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
high_value_customers AS (
    SELECT ch.c_custkey, ch.c_name, ch.c_acctbal, COALESCE(tov.total_value, 0) AS total_value
    FROM customer_hierarchy ch
    LEFT JOIN total_order_value tov ON ch.c_custkey = tov.o_custkey
    WHERE ch.level = 0 AND ch.c_acctbal IS NOT NULL
),
suppliers_by_region AS (
    SELECT n.n_regionkey, s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_regionkey, s.s_suppkey, s.s_name
)
SELECT 
    r.r_name,
    hvc.c_name,
    hvc.total_value,
    COALESCE(SUM(sbr.total_supply_cost), 0) AS total_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY hvc.total_value DESC) AS rank
FROM region r
LEFT JOIN high_value_customers hvc ON hvc.total_value > 10000
LEFT JOIN suppliers_by_region sbr ON sbr.n_regionkey = r.r_regionkey
GROUP BY r.r_name, hvc.c_name, hvc.total_value
HAVING COUNT(sbr.s_suppkey) > 0 OR hvc.total_value IS NOT NULL
ORDER BY r.r_name, rank;
