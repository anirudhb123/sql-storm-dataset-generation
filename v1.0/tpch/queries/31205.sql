WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS depth
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.depth * 5000
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY c.c_custkey, c.c_name
),
high_value_customers AS (
    SELECT c.c_custkey, c.c_name, co.total_spent
    FROM customer_orders co
    JOIN customer c ON co.c_custkey = c.c_custkey
    WHERE co.total_spent > (SELECT AVG(total_spent) FROM customer_orders)
),
part_supplier_info AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    AVG(li.l_quantity) AS avg_line_quantity,
    HVC.c_name AS high_value_customer,
    PSI.p_name AS part_name,
    PSI.total_supply_cost
FROM lineitem li
JOIN orders o ON li.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation ns ON c.c_nationkey = ns.n_nationkey
JOIN region r ON ns.n_regionkey = r.r_regionkey
LEFT JOIN high_value_customers HVC ON c.c_custkey = HVC.c_custkey
JOIN part_supplier_info PSI ON li.l_partkey = PSI.p_partkey
WHERE li.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
AND (li.l_returnflag IS NULL OR li.l_returnflag = 'N')
GROUP BY r.r_name, ns.n_name, HVC.c_name, PSI.p_name, PSI.total_supply_cost
ORDER BY total_revenue DESC
LIMIT 100;