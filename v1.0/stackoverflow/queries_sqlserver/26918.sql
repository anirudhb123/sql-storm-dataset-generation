
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        value AS Tag
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') AS TagSplit
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
        TagPopularities pt ON pt.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>'))
    WHERE 
        p.PostTypeId = 1 
    ORDER BY 
        p.LastActivityDate DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
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
