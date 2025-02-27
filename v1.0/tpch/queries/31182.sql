WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s2.s_suppkey, s2.s_name, s2.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s2 ON ps.ps_partkey = s2.s_suppkey
    WHERE sh.level < 3
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS total_lines
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
      AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY o.o_orderkey
),
high_value_orders AS (
    SELECT os.o_orderkey, os.total_revenue, os.total_lines
    FROM order_summary os
    WHERE os.total_revenue > 10000
)
SELECT 
    nh.n_name AS nation_name,
    COUNT(DISTINCT supp.s_suppkey) AS total_suppliers,
    AVG(supp.s_acctbal) AS avg_supplier_balance,
    AVG(o.total_revenue) AS avg_order_revenue,
    SUM(CASE WHEN o.total_lines > 5 THEN 1 ELSE 0 END) AS high_line_orders
FROM high_value_orders o
LEFT JOIN customer c ON c.c_custkey = (SELECT o_custkey FROM orders WHERE o_orderkey = o.o_orderkey)
LEFT JOIN supplier supp ON supp.s_nationkey = c.c_nationkey
JOIN nation nh ON nh.n_nationkey = c.c_nationkey
GROUP BY nh.n_name
HAVING AVG(supp.s_acctbal) IS NOT NULL
ORDER BY total_suppliers DESC, avg_order_revenue DESC
LIMIT 10;