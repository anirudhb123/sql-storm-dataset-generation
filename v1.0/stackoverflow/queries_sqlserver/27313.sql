
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        value AS Tag
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') 
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
        STRING_AGG(DISTINCT pt.Tag, ',') AS Tags
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
    OFFSET 0 ROWS 
    FETCH NEXT 10 ROWS ONLY
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
    PopularTags pm ON pm.Tag IN (SELECT value FROM STRING_SPLIT(tq.Tags, ','))
ORDER BY 
    tq.Score DESC, 
    pm.TagCount DESC;
