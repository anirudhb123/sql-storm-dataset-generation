WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank,
        COUNT(l.l_shipinstruct) OVER (PARTITION BY o.o_orderkey) AS lineitem_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
),
distinct_suppliers AS (
    SELECT 
        DISTINCT s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        p.p_type,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Balance'
            WHEN s.s_acctbal < 1000 THEN 'Low Balance'
            WHEN s.s_acctbal BETWEEN 1000 AND 5000 THEN 'Medium Balance'
            ELSE 'High Balance'
        END AS balance_category
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_container LIKE 'SMALL%'
),
final_summary AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        s.nation_name,
        s.balance_category,
        ro.lineitem_count,
        GREATEST(ro.lineitem_count, COUNT(DISTINCT s.s_suppkey)) OVER () AS max_suppliers_for_order
    FROM 
        ranked_orders ro
    LEFT JOIN 
        distinct_suppliers s ON ro.o_orderkey = s.s_suppkey
    WHERE 
        ro.price_rank <= 5
    ORDER BY 
        ro.o_orderdate DESC NULLS LAST
)
SELECT 
    fs.o_orderkey,
    fs.o_orderdate,
    FS.lineitem_count,
    COALESCE(fs.nation_name, 'Unknown') AS nation_name,
    fs.max_suppliers_for_order,
    CASE 
        WHEN fs.lineitem_count > 10 AND fs.balance_category = 'High Balance' THEN 'Flagged for Review'
        ELSE 'Normal'
    END AS order_review_status
FROM 
    final_summary fs
FULL OUTER JOIN 
    orders o ON fs.o_orderkey = o.o_orderkey
WHERE 
    o.o_orderstatus IS NOT NULL
    AND (fs.balance_category IS NOT NULL OR fs.lineitem_count = 0)
    AND fs.o_orderdate < (CURRENT_DATE - INTERVAL '30 days')
UNION ALL
SELECT 
    NULL AS o_orderkey,
    NULL AS o_orderdate,
    SUM(ps.ps_availqty) AS total_available_quantity,
    'Aggregate' AS nation_name,
    NULL AS max_suppliers_for_order,
    'Aggregated' AS order_review_status
FROM 
    partsupp ps
GROUP BY 
    ps.ps_partkey
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 2
ORDER BY 
    o_orderdate DESC NULLS LAST;
