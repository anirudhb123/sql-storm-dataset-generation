WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
total_costs AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
),
ranking AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM customer_orders o
    JOIN customer c ON o.c_custkey = c.c_custkey
),
high_value_orders AS (
    SELECT r.c_custkey, r.c_name, r.o_orderkey, r.o_totalprice
    FROM ranking r
    WHERE r.rank_order <= 5
),
supplier_costs AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT 
    r.c_custkey, r.c_name,
    s.s_name,
    COALESCE(sc.total_supply_cost, 0) AS supplier_cost, 
    tc.total_supply_cost AS part_supply_cost
FROM high_value_orders r
LEFT JOIN supplier s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
LEFT JOIN supplier_costs sc ON s.s_suppkey = sc.s_suppkey
LEFT JOIN total_costs tc ON tc.ps_partkey = (SELECT ps.ps_partkey 
                                              FROM partsupp ps 
                                              WHERE ps.ps_supplycost > 1000 
                                              ORDER BY ps.ps_supplycost DESC LIMIT 1)
WHERE r.o_totalprice > (SELECT AVG(r2.o_totalprice) FROM high_value_orders r2)
ORDER BY r.c_name, supplier_cost DESC;
