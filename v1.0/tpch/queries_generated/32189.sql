WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 3
),
part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND (c.c_mktsegment = 'BUILDING' OR c.c_mktsegment IS NULL)
    GROUP BY c.c_custkey
),
ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
)
SELECT 
    p.p_name AS part_name,
    ns.n_name AS supplier_nation,
    c.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    COALESCE(SUM(l.l_discount * l.l_extendedprice), 0) AS total_discounted_price,
    sh.level AS supplier_level
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN part_supplier ps ON ps.ps_partkey = p.p_partkey
JOIN ranked_suppliers s ON s.s_suppkey = l.l_suppkey
JOIN nation ns ON ns.n_nationkey = s.s_nationkey
JOIN customer_orders co ON co.c_custkey = l.l_suppkey
LEFT JOIN supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
WHERE p.p_retailprice > 100 AND (sh.level IS NULL OR sh.level < 2)
GROUP BY p.p_name, ns.n_name, c.c_name, co.order_count, co.total_spent, sh.level
HAVING SUM(l.l_quantity) > 50
ORDER BY total_discounted_price DESC
LIMIT 10;
