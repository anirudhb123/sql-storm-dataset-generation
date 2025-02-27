WITH StringMetrics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        LENGTH(p.p_name) AS name_length,
        SUBSTRING(p.p_comment FROM 1 FOR 15) AS short_comment,
        REGEXP_REPLACE(p.p_comment, '[^a-zA-Z0-9]', ' ') AS cleaned_comment,
        UPPER(p.p_brand) AS upper_brand,
        LOWER(p.p_type) AS lower_type,
        REPLACE(p.p_name, ' ', '-') AS hyphenated_name
    FROM part p
), Benchmarking AS (
    SELECT 
        sm.p_partkey,
        sm.p_name,
        sm.name_length,
        sm.short_comment,
        sm.cleaned_comment,
        sm.upper_brand,
        sm.lower_type,
        sm.hyphenated_name,
        COUNT(DISTINCT (s.s_suppkey)) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(l.l_quantity) AS total_quantity
    FROM StringMetrics sm
    LEFT JOIN partsupp ps ON sm.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN lineitem l ON sm.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY sm.p_partkey, sm.p_name, sm.name_length, sm.short_comment, sm.cleaned_comment, sm.upper_brand, sm.lower_type, sm.hyphenated_name
)
SELECT 
    *,
    CASE 
        WHEN total_orders > 0 THEN total_quantity / total_orders 
        ELSE 0 
    END AS average_quantity_per_order
FROM Benchmarking
ORDER BY name_length DESC, total_supply_cost DESC;
