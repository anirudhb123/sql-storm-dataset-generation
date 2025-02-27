
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
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
