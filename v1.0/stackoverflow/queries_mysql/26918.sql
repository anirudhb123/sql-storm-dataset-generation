
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
         UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.PostTypeId = 1 
),
TagPopularities AS (
    SELECT 
        Tag,
        COUNT(*) AS QuestionCount
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
    ORDER BY 
        QuestionCount DESC
    LIMIT 10
),
LatestPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerDisplayName,
        pt.QuestionCount
    FROM 
        Posts p
    INNER JOIN 
        TagPopularities pt ON pt.Tag IN (SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1))
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
         UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.PostTypeId = 1 
    ORDER BY 
        p.LastActivityDate DESC
    LIMIT 5 
)
SELECT 
    lp.Title AS RecentQuestion,
    lp.CreationDate AS PostedOn,
    lp.ViewCount AS Views,
    lp.OwnerDisplayName AS Author,
    tp.Tag AS PopularTag,
    tp.QuestionCount AS TagUsage 
FROM 
    LatestPosts lp
JOIN 
    TagPopularities tp ON lp.QuestionCount = tp.QuestionCount 
ORDER BY 
    lp.CreationDate DESC;
