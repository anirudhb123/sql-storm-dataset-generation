WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment, 1 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS total_parts,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS nation_rank
    FROM supplier s
),
high_value_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_nationkey,
        COUNT(l.l_orderkey) AS total_line_items
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_totalprice > 1000
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_nationkey
),
final_analysis AS (
    SELECT 
        nh.n_name AS nation_name,
        sd.s_name AS supplier_name,
        hd.o_orderkey,
        hd.o_totalprice,
        hd.total_line_items
    FROM supplier_details sd
    JOIN nation_hierarchy nh ON sd.s_nationkey = nh.n_nationkey
    LEFT JOIN high_value_orders hd ON sd.s_suppkey = hd.o_orderkey
    WHERE sd.total_parts >= 3
)
SELECT 
    fa.nation_name,
    fa.supplier_name,
    SUM(fa.o_totalprice) AS total_value,
    AVG(fa.total_line_items) AS avg_items,
    COUNT(DISTINCT fa.o_orderkey) AS order_count
FROM final_analysis fa
GROUP BY fa.nation_name, fa.supplier_name
HAVING total_value > (SELECT AVG(o_totalprice) FROM high_value_orders WHERE c_nationkey = fa.nation_name)
ORDER BY total_value DESC;
