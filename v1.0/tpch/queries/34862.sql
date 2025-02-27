WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_name = 'USA'
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplied,
        COUNT(DISTINCT ps.ps_partkey) AS parts_provided
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
lineitem_summary AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_orders,
        AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    GROUP BY l.l_partkey
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.p_size,
    COALESCE(ls.total_revenue, 0) AS total_revenue,
    COALESCE(cs.total_spent, 0) AS customer_spending,
    ss.total_supplied,
    ss.parts_provided,
    nh.n_name AS nation_name
FROM part p
LEFT JOIN lineitem_summary ls ON p.p_partkey = ls.l_partkey
LEFT JOIN customer_orders cs ON p.p_partkey = cs.c_custkey
LEFT JOIN supplier_stats ss ON p.p_partkey = ss.s_suppkey
LEFT JOIN nation_hierarchy nh ON nh.n_nationkey = (SELECT MIN(n_nationkey) FROM nation WHERE n_name = 'USA')
WHERE p.p_retailprice > 10.00 AND ss.total_supplied > 1000
ORDER BY total_revenue DESC NULLS LAST
LIMIT 100;
