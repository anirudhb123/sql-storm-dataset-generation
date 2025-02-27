
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s2.s_name, s2.s_nationkey, sh.level + 1
    FROM partsupp ps
    JOIN supplier s2 ON ps.ps_suppkey = s2.s_suppkey
    JOIN supplier_hierarchy sh ON ps.ps_partkey = sh.s_suppkey
    WHERE sh.level < 3
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS total_lines
    FROM lineitem l
    GROUP BY l.l_orderkey
),
high_value_orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        l.total_revenue,
        l.total_lines,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN lineitem_summary l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F' AND o.o_totalprice > 1000
),
customer_growth AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000
)
SELECT 
    r.r_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(cg.total_spent) AS average_customer_spending,
    MAX(HV.total_revenue) AS max_order_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN customer_growth cg ON cg.c_custkey = s.s_suppkey
LEFT JOIN high_value_orders HV ON HV.o_orderkey = s.s_suppkey
WHERE r.r_name IS NOT NULL OR s.s_comment IS NOT NULL
GROUP BY r.r_name
ORDER BY average_customer_spending DESC
LIMIT 10;
