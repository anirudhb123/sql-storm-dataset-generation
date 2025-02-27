WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PopularParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 100
),
DistinctComments AS (
    SELECT DISTINCT
        p.p_comment
    FROM 
        part p
    WHERE 
        LENGTH(p.p_comment) > 15
),
StringAnalysis AS (
    SELECT 
        p.p_name,
        LTRIM(RTRIM(p.p_name)) AS trimmed_name,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_name) AS lower_name,
        CHAR_LENGTH(p.p_name) AS name_length,
        SUBSTRING(p.p_name, 1, 10) AS name_substring
    FROM 
        part p
    WHERE 
        p.p_type LIKE '%rose%'
)
SELECT 
    rs.s_name,
    rs.s_acctbal,
    pp.total_availqty,
    pp.supplier_count,
    sc.p_comment,
    sa.trimmed_name,
    sa.upper_name,
    sa.lower_name,
    sa.name_length,
    sa.name_substring
FROM 
    RankedSuppliers rs
JOIN 
    PopularParts pp ON pp.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey)
JOIN 
    DistinctComments sc ON sc.p_comment LIKE '%' || rs.s_name || '%'
JOIN 
    StringAnalysis sa ON sa.p_name LIKE '%' || rs.s_name || '%'
WHERE 
    rs.rn <= 5
ORDER BY 
    rs.s_acctbal DESC, pp.total_availqty DESC;
