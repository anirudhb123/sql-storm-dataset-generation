WITH region_summary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(n.n_nationkey) AS nation_count,
        SUM(COALESCE(s.s_acctbal, 0)) AS total_acctbal,
        STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
average_price AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
),
high_value_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
part_supplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    r.r_name,
    r.nation_count,
    r.total_acctbal,
    r.supplier_comments,
    p.p_name,
    p.rank, 
    a.avg_supplycost,
    o.order_value,
    CASE 
        WHEN o.line_item_count > 5 THEN 'High'
        ELSE 'Low'
    END AS order_importance
FROM region_summary r
LEFT JOIN part_supplier p ON p.rank = 1
LEFT JOIN average_price a ON p.p_partkey = a.ps_partkey
LEFT JOIN high_value_orders o ON o.o_orderkey = (
    SELECT o_orderkey 
    FROM high_value_orders ho 
    WHERE ho.line_item_count = (SELECT MAX(line_item_count) FROM high_value_orders)
    LIMIT 1
)
WHERE r.nation_count IS NOT NULL 
  AND r.total_acctbal IS NOT NULL
ORDER BY r.r_name, o.order_value DESC NULLS LAST;
