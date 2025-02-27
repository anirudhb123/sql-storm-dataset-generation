WITH RECURSIVE supplier_nations AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 1 AS level 
    FROM nation n
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, sn.level + 1 
    FROM nation n
    JOIN supplier_nations sn ON n.n_regionkey = sn.n_regionkey
    WHERE sn.level < 5
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(DISTINCT l.l_linenumber) AS item_count,
           MAX(o.o_orderdate) AS max_order_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
top_orders AS (
    SELECT os.o_orderkey, os.total_price, os.item_count,
           RANK() OVER (ORDER BY os.total_price DESC) AS rank
    FROM order_summary os
    WHERE os.item_count > 1
)
SELECT 
    sn.n_name AS nation_name,
    COUNT(DISTINCT so.o_orderkey) AS total_orders,
    SUM(so.total_price) AS total_revenue,
    AVG(so.total_price) AS avg_order_value,
    CASE 
        WHEN AVG(so.total_price) IS NULL THEN 'No Orders'
        ELSE 'Orders Available'
    END AS order_status
FROM supplier_nations sn
LEFT JOIN supplier s ON sn.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey 
LEFT JOIN top_orders so ON l.l_orderkey = so.o_orderkey 
WHERE p.p_retailprice > 10 AND (s.s_acctbal IS NULL OR s.s_acctbal > 500)
GROUP BY sn.n_name
ORDER BY total_revenue DESC
LIMIT 10;
