WITH StringProcessing AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        UPPER(p.p_comment) AS upper_comment,
        LOWER(p.p_name) AS lower_name,
        LENGTH(p.p_name) AS name_length,
        SUBSTRING(p.p_comment FROM 1 FOR 10) AS comment_excerpt,
        REPLACE(p.p_comment, 'special', 'standard') AS modified_comment,
        ARRAY_AGG(DISTINCT SUBSTRING(p.p_name FROM 1 FOR 3)) AS name_prefixes
    FROM 
        part p
    GROUP BY 
        p.p_partkey, 
        p.p_name
),
NationSupplier AS (
    SELECT 
        n.n_name AS nation_name, 
        s.s_name AS supplier_name, 
        LENGTH(s.s_address) AS address_length,
        CONCAT(s.s_name, ' - ', n.n_name) AS supplier_nation_combo
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
OrderAnalysis AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        CONCAT('Order #', o.o_orderkey, ' - Price: $', o.o_totalprice) AS order_description,
        YEAR(o.o_orderdate) AS order_year,
        DATE_TRUNC('month', o.o_orderdate) AS order_month
    FROM 
        orders o
)
SELECT 
    sp.p_partkey, 
    sp.upper_comment, 
    ns.nation_name, 
    ns.supplier_name, 
    oa.order_description, 
    oa.order_year, 
    sp.comment_excerpt, 
    sp.modified_comment
FROM 
    StringProcessing sp
JOIN 
    partsupp ps ON sp.p_partkey = ps.ps_partkey
JOIN 
    NationSupplier ns ON ps.ps_suppkey = ns.supplier_name
JOIN 
    order_analysis oa ON ps.ps_partkey = oa.o_orderkey
WHERE 
    sp.name_length > 10 
    AND ns.address_length < 30
ORDER BY 
    sp.p_partkey, 
    ns.nation_name;
