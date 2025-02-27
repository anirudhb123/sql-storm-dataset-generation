
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COALESCE((
            SELECT COUNT(*)
            FROM Comments c
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount,
        value AS Tag
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '><')
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
        AND p.PostTypeId IN (1, 2) 
),

RankedPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Body,
        fp.Tag,
        fp.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY fp.Tag ORDER BY fp.CommentCount DESC) AS TagRank
    FROM 
        FilteredPosts fp
),

PopularTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TotalPosts
    FROM 
        RankedPosts
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5 
)

SELECT 
    pt.Tag,
    COUNT(rp.PostId) AS NumberOfPosts,
    MAX(rp.CommentCount) AS MostComments,
    MIN(rp.CommentCount) AS LeastComments,
    AVG(rp.CommentCount) AS AvgComments
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Tag = pt.Tag
GROUP BY 
    pt.Tag
ORDER BY 
    NumberOfPosts DESC;
