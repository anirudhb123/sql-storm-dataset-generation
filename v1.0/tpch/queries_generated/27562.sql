WITH StringMetrics AS (
    SELECT 
        s.s_name AS supplier_name,
        SUBSTRING(s.s_comment FROM 1 FOR 25) AS short_comment,
        LENGTH(s.s_comment) AS comment_length,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS part_count,
        s.s_acctbal AS account_balance,
        (SELECT AVG(LENGTH(p.p_comment)) FROM part p INNER JOIN partsupp ps ON p.p_partkey = ps.ps_partkey WHERE ps.ps_suppkey = s.s_suppkey) AS avg_part_comment_length
    FROM 
        supplier s
    WHERE 
        LENGTH(s.s_comment) > 10
)
SELECT 
    rm.r_name AS region_name,
    nm.n_name AS nation_name,
    STRING_AGG(sm.supplier_name, ', ') AS suppliers,
    SUM(sm.comment_length) AS total_comment_length,
    AVG(sm.avg_part_comment_length) AS avg_part_comment_length,
    COUNT(DISTINCT sm.supplier_name) AS unique_suppliers_count,
    SUM(sm.account_balance) AS total_balance
FROM 
    StringMetrics sm
JOIN 
    supplier s ON s.s_name = sm.supplier_name
JOIN 
    nation nm ON s.s_nationkey = nm.n_nationkey
JOIN 
    region rm ON nm.n_regionkey = rm.r_regionkey
GROUP BY 
    rm.r_name, nm.n_name
ORDER BY 
    total_comment_length DESC;
