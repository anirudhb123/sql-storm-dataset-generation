WITH StringBenchmark AS (
    SELECT 
        p.p_name, 
        CONCAT('Part Name: ', p.p_name, ' | Brand: ', p.p_brand, ' | Comment: ', p.p_comment) AS DetailedDescription,
        LENGTH(p.p_name) AS NameLength,
        LENGTH(p.p_comment) AS CommentLength,
        LOWER(SUBSTRING(p.p_name, 1, 10)) AS ShortName,
        UPPER(SUBSTRING(p.p_comment, 1, 15)) AS ShortComment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 50000
),
AggregatedResults AS (
    SELECT 
        AVG(NameLength) AS AvgNameLength,
        AVG(CommentLength) AS AvgCommentLength,
        COUNT(DISTINCT DetailedDescription) AS UniqueDescriptions,
        COUNT(*) AS TotalParts
    FROM 
        StringBenchmark
)
SELECT 
    a.AvgNameLength, 
    a.AvgCommentLength, 
    a.UniqueDescriptions, 
    a.TotalParts,
    STRING_AGG(SHORTNAME, ', ') AS ShortNames
FROM 
    AggregatedResults a,
    StringBenchmark b
GROUP BY 
    a.AvgNameLength, a.AvgCommentLength, a.UniqueDescriptions, a.TotalParts;
