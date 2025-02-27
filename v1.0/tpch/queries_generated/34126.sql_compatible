
WITH RECURSIVE category_hierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_retailprice,
           p_comment, 1 AS level
    FROM part
    WHERE p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, 
           p.p_retailprice, p.p_comment, ch.level + 1
    FROM part p
    JOIN category_hierarchy ch ON p.p_partkey = ch.p_partkey
    WHERE p.p_size < 50
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           CASE WHEN s.s_acctbal IS NULL THEN 'No Balance' ELSE 'Has Balance' END AS balance_status
    FROM supplier s
    WHERE s.s_acctbal > 500
),
order_summary AS (
    SELECT o.o_orderkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_orderkey, c.c_name
),
nation_agg AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_name, COALESCE(na.supplier_count, 0) AS total_suppliers,
       COALESCE(nc.total_balance, 0) AS total_balance,
       AVG(os.total_sales) AS avg_order_value
FROM region r
LEFT JOIN nation_agg na ON r.r_regionkey = na.n_nationkey
LEFT JOIN order_summary os ON os.o_orderkey = na.supplier_count
LEFT JOIN (
    SELECT n.n_nationkey, SUM(s.s_acctbal) AS total_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
) nc ON na.n_nationkey = nc.n_nationkey
GROUP BY r.r_name, na.supplier_count, nc.total_balance
ORDER BY total_balance DESC, total_suppliers DESC;
