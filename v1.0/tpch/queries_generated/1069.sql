WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F' OR o.o_orderstatus IS NULL
    GROUP BY c.c_custkey, c.c_name
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, c.accountbalance, co.order_count, co.avg_order_value
    FROM customer c
    JOIN customer_orders co ON c.c_custkey = co.c_custkey
    WHERE co.order_count > 2
),
part_statistics AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supply_cost, COUNT(ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    p.p_name,
    ps.avg_supply_cost,
    pc.supplier_count,
    c.c_name,
    CASE 
        WHEN c.c_acctbal IS NULL THEN 'No account balance'
        ELSE CONCAT('Balance: ', c.c_acctbal)
    END AS balance_info,
    RANK() OVER (PARTITION BY c.c_nationkey ORDER BY co.order_count DESC) AS customer_rank
FROM part_statistics ps
JOIN top_customers c ON ps.supplier_count > c.order_count
LEFT JOIN supplier_hierarchy sh ON c.c_custkey = sh.s_suppkey
LEFT JOIN customer_orders co ON c.c_custkey = co.c_custkey
WHERE ps.avg_supply_cost > (SELECT AVG(ps_supplycost) FROM partsupp)
    AND EXISTS (SELECT 1 FROM nation n WHERE n.n_nationkey = c.c_nationkey AND n.n_name LIKE 'United%')
ORDER BY ps.avg_supply_cost DESC, c.c_name ASC;
