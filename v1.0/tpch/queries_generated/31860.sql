WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
high_value_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice > 100.00
),
filtered_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
total_line_items AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    WHERE l.l_shipdate <= CURRENT_DATE
    GROUP BY l.l_orderkey
)
SELECT 
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COALESCE(SUM(tli.total_price), 0) AS total_revenue,
    COUNT(DISTINCT fo.o_orderkey) AS order_count,
    MAX(sh.level) AS highest_supplier_level
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN filtered_orders fo ON fo.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN total_line_items tli ON tli.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = fo.o_custkey)
JOIN high_value_parts p ON p.p_partkey = ANY(SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
LEFT JOIN supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
WHERE p.p_retailprice IS NOT NULL
GROUP BY n.n_name, s.s_name, p.p_name
HAVING total_revenue > (SELECT AVG(total_price) FROM total_line_items)
ORDER BY total_revenue DESC, highest_supplier_level;
