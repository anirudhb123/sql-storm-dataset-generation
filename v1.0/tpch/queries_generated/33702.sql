WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s1.s_acctbal) FROM supplier s1
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
order_summary AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY c.c_custkey
),
part_costs AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
supply_partition AS (
    SELECT sh.s_suppkey, sh.s_name, sh.s_acctbal, pc.total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY sh.level ORDER BY sh.s_acctbal DESC) AS rank
    FROM supplier_hierarchy sh
    LEFT JOIN part_costs pc ON sh.s_suppkey = pc.p_partkey
)
SELECT o.custkey, o.order_count, o.total_spent, sp.s_name, sp.total_supply_cost
FROM order_summary o
JOIN supply_partition sp ON o.c_custkey = sp.s_suppkey
WHERE sp.rank <= 5 AND sp.total_supply_cost IS NOT NULL
UNION
SELECT o.custkey, o.order_count, o.total_spent, NULL AS s_name, NULL AS total_supply_cost
FROM order_summary o
WHERE NOT EXISTS (
    SELECT 1 FROM supply_partition sp WHERE o.c_custkey = sp.s_suppkey
)
ORDER BY o.total_spent DESC, o.order_count DESC;
