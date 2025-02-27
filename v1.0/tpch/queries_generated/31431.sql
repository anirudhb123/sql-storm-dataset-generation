WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_suppkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS total_items
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2022-01-01'
    GROUP BY l.l_orderkey
),
customer_orders AS (
    SELECT c.c_custkey,
           c.c_name,
           c.c_acctbal,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c1.c_acctbal) FROM customer c1)
    GROUP BY c.c_custkey
),
high_value_suppliers AS (
    SELECT ps.ps_suppkey,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
    HAVING COUNT(DISTINCT ps.ps_partkey) > 10
)
SELECT 
    c.c_name,
    c.order_count,
    c.total_spent,
    sh.level,
    sh.s_name AS supplier_name,
    sh.s_address AS supplier_address,
    hv.avg_supply_cost
FROM customer_orders c
JOIN supplier_hierarchy sh ON c.c_custkey = sh.s_nationkey
LEFT JOIN high_value_suppliers hv ON sh.s_suppkey = hv.ps_suppkey
WHERE c.order_count > 5
ORDER BY c.total_spent DESC, sh.s_name ASC
LIMIT 100;

