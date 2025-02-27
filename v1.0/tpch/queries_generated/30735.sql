WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 3 AND s.s_acctbal > 50000
), 
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), 
part_supplier AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    ps.p_name,
    ps.total_supply_cost,
    cs.total_order_value,
    cs.order_count,
    ns.n_name AS supplier_nation,
    s.s_name AS supplier_name 
FROM part_supplier ps
JOIN lineitem l ON ps.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer_order_summary cs ON cs.c_custkey = o.o_custkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN nation ns ON s.s_nationkey = ns.n_nationkey
WHERE ps.total_supply_cost > (SELECT AVG(total_supply_cost) FROM part_supplier) 
AND (s.s_acctbal IS NULL OR s.s_acctbal > 10000)
    AND cs.rank <= 5
ORDER BY ps.total_supply_cost DESC, cs.total_order_value DESC;
