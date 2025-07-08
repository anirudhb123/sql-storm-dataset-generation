
WITH StringProcessing AS (
    SELECT 
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        LOWER(p.p_name) AS lower_case_name,
        UPPER(p.p_name) AS upper_case_name,
        REPLACE(p.p_comment, 'the', 'THE') AS modified_comment,
        CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand) AS mfgr_and_brand,
        TRIM(p.p_container) AS trimmed_container
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 20
),
NationSupplier AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
OrderProcessing AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    sp.p_name,
    sp.name_length,
    sp.lower_case_name,
    ns.nation_name,
    ns.supplier_count,
    op.total_revenue,
    op.distinct_parts
FROM 
    StringProcessing sp
LEFT JOIN 
    NationSupplier ns ON ns.nation_name = (
        SELECT n.n_name 
        FROM nation n 
        JOIN supplier s ON s.s_nationkey = n.n_nationkey 
        WHERE s.s_name = sp.lower_case_name 
        LIMIT 1
    )
LEFT JOIN 
    OrderProcessing op ON op.o_orderkey = (
        SELECT o.o_orderkey 
        FROM orders o 
        JOIN customer c ON c.c_custkey = o.o_custkey 
        WHERE c.c_name = sp.lower_case_name 
        LIMIT 1
    )
ORDER BY 
    sp.name_length DESC, op.total_revenue DESC;
