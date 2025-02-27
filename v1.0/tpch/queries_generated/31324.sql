WITH RECURSIVE ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
filtered_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'N/A'
            ELSE CONCAT('$', CAST(p.p_retailprice AS VARCHAR))
        END AS retail_price_display
    FROM part p
    WHERE p.p_size > 10
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
high_value_summary AS (
    SELECT 
        os.o_orderkey,
        os.total_order_value,
        os.distinct_parts_count,
        CASE 
            WHEN os.distinct_parts_count > 5 THEN 'High Diversity'
            ELSE 'Low Diversity'
        END AS diversity_category
    FROM order_summary os
    WHERE os.total_order_value > 1000
),
supplier_parts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_name,
    p.retail_price_display,
    COALESCE(sp.supplier_count, 0) AS supplier_count,
    hs.total_order_value,
    hs.diversity_category,
    n.n_name AS nation_name
FROM filtered_parts p
LEFT JOIN supplier_parts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN high_value_summary hs ON sp.supplier_count > 0
LEFT JOIN supplier s ON s.s_suppkey = hs.o_orderkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE p.p_mfgr = 'Manufacturer1'
   OR (p.p_container = 'Box' AND n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%east%'))
ORDER BY p.p_retailprice DESC, hs.total_order_value DESC;
