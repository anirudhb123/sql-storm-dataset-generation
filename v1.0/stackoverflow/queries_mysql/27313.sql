
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1  
),
TagMetrics AS (
    SELECT 
        pt.Tag,
        COUNT(*) AS TagCount,
        COUNT(DISTINCT pt.PostId) AS PostCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        PostTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        pt.Tag
),
PopularTags AS (
    SELECT 
        Tag, 
        TagCount, 
        PostCount, 
        AvgUserReputation
    FROM 
        TagMetrics
    WHERE 
        TagCount > (SELECT AVG(TagCount) FROM TagMetrics)
),
TopQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        GROUP_CONCAT(DISTINCT pt.Tag) AS Tags
    FROM 
        Posts p
    JOIN 
        PostTags pt ON p.Id = pt.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.CreationDate
    ORDER BY 
        p.Score DESC
    LIMIT 10
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.Score,
    tq.ViewCount,
    tq.AnswerCount,
    tq.CommentCount,
    tq.CreationDate,
    pm.Tag AS PopularTag,
    pm.TagCount,
    pm.PostCount,
    pm.AvgUserReputation
FROM 
    TopQuestions tq
JOIN 
    PopularTags pm ON FIND_IN_SET(pm.Tag, tq.Tags) > 0
ORDER BY 
    tq.Score DESC, 
    pm.TagCount DESC;
