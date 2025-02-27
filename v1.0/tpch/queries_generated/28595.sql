WITH ProcessedParts AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_brand) AS lower_brand,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(p.p_type, ' ', '_') AS type_with_underscore
    FROM 
        part p
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    pp.p_partkey,
    pp.upper_name,
    pp.lower_brand,
    pp.comment_length,
    pp.type_with_underscore,
    ns.n_name,
    ns.supplier_count,
    ns.supplier_names,
    ns.total_account_balance
FROM 
    ProcessedParts pp
JOIN 
    NationSummary ns ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
ORDER BY 
    pp.comment_length DESC, ns.total_account_balance ASC;
