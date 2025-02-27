WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 1000
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, h.level + 1
    FROM orders o
    JOIN order_hierarchy h ON o.o_custkey = h.o_custkey
    WHERE o.o_orderdate > h.o_orderdate
),
supplier_availability AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(SUM(ls.total_revenue), 0) AS total_revenue,
    COALESCE(SUM(sa.total_available), 0) AS total_parts_available,
    AVG(CASE WHEN oh.level > 1 THEN oh.o_totalprice END) AS avg_hierarchy_order_value
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN lineitem_summary ls ON o.o_orderkey = ls.l_orderkey
LEFT JOIN supplier_availability sa ON p.p_partkey = sa.ps_partkey
LEFT JOIN order_hierarchy oh ON o.o_orderkey = oh.o_orderkey
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_orders DESC, total_revenue DESC;
