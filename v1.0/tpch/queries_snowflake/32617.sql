WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) AND sh.level < 5
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
customer_details AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, o.o_orderkey, os.total_revenue
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN order_summary os ON o.o_orderkey = os.o_orderkey
    WHERE c.c_acctbal IS NOT NULL AND os.total_revenue IS NOT NULL
)

SELECT 
    r.r_name,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    SUM(DISTINCT ps.ps_availqty) AS total_available_qty,
    COALESCE(SUM(cs.total_revenue), 0) AS total_revenue_collected
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN part_supplier ps ON sh.s_suppkey = ps.ps_suppkey
LEFT JOIN customer_details cs ON cs.o_orderkey = (SELECT MAX(o_orderkey) FROM orders)
WHERE r.r_name LIKE '%Eastern%'
GROUP BY r.r_name
ORDER BY supplier_count DESC, total_revenue_collected DESC;
