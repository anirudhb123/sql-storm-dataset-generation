WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
part_details AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, ps.ps_availqty, 
           ps.ps_supplycost, (ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY total_supply_cost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size > 10 AND p.p_retailprice IS NOT NULL
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           CASE WHEN SUM(o.o_totalprice) > 10000 THEN 'VIP' ELSE 'Regular' END AS customer_class
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
nation_stats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    ph.p_partkey,
    ph.p_name,
    ph.p_brand,
    ph.total_supply_cost,
    cu.total_spent,
    ns.supplier_count,
    CASE WHEN ph.total_supply_cost > 10000 THEN 'High' ELSE 'Low' END AS supply_category,
    ROW_NUMBER() OVER (PARTITION BY cu.customer_class ORDER BY cu.total_spent DESC) AS rank_in_class
FROM part_details ph
JOIN customer_order_summary cu ON ph.p_partkey = cu.c_custkey
LEFT JOIN nation_stats ns ON cu.total_spent > 5000 AND ns.n_nationkey IN (SELECT s_nationkey FROM supplier WHERE s_acctbal IS NOT NULL)
WHERE ph.rn = 1
ORDER BY rank_in_class, ph.total_supply_cost DESC;
