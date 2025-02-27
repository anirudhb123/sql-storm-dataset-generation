WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, CONCAT(s.s_name, ' (sub)') AS s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 3
),
available_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) as rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
),
orders_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) as total_items,
           AVG(o.o_totalprice) OVER() as avg_order_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
       SUM(COALESCE(ap.ps_availqty, 0)) AS total_available_qty,
       AVG(os.total_revenue) FILTER (WHERE os.total_items > 5) AS avg_high_value_order
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN available_parts ap ON ap.p_partkey = (
    SELECT p2.p_partkey
    FROM part p2
    WHERE p2.p_retailprice = (
        SELECT MAX(p3.p_retailprice)
        FROM part p3
        WHERE p3.p_size < ALL (SELECT DISTINCT size FROM part)
    ) LIMIT 1
)
LEFT JOIN orders_summary os ON os.o_orderkey IN (
    SELECT o2.o_orderkey
    FROM orders o2
    WHERE o2.o_orderstatus = 'O' OR o2.o_orderstatus IS NULL
)
GROUP BY r.r_name
HAVING COUNT(DISTINCT n.n_nationkey) < (SELECT COUNT(DISTINCT n2.n_nationkey) FROM nation n2)
ORDER BY nation_count DESC, total_available_qty ASC
LIMIT 10;
