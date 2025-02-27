WITH RECURSIVE supplier_cte AS (
    SELECT s_suppkey, s_name, s_acctbal, NULL AS parent_suppkey
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, c.s_suppkey
    FROM supplier s
    JOIN supplier_cte c ON s.s_acctbal > c.s_acctbal
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, os.total_revenue, os.line_item_count
    FROM orders o
    JOIN order_summary os ON o.o_orderkey = os.o_orderkey
    WHERE os.total_revenue > (SELECT AVG(total_revenue) FROM order_summary)
)
SELECT 
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    (CASE 
        WHEN COUNT(DISTINCT l.l_orderkey) > 100 
        THEN 'High Volume'
        ELSE 'Low Volume'
    END) AS volume_status
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN high_value_orders hvo ON l.l_orderkey = hvo.o_orderkey
WHERE p.p_retailprice > 100
GROUP BY p.p_name
HAVING SUM(l.l_quantity) IS NOT NULL
ORDER BY total_quantity DESC, avg_supplier_acctbal DESC;
