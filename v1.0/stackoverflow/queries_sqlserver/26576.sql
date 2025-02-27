
WITH TagUsage AS (
    SELECT 
        value AS Tag,
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(Tags, '>') AS t
    WHERE 
        PostTypeId = 1 
),
TopTags AS (
    SELECT 
        Tag, 
        COUNT(PostId) AS UsageCount
    FROM 
        TagUsage
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
PopularQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        STRING_AGG(t.Tag, ', ') AS RelatedTags
    FROM 
        Posts p
    JOIN 
        TagUsage t ON p.Id = t.PostId
    WHERE 
        t.Tag IN (SELECT Tag FROM TopTags)
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount, p.CommentCount, p.CreationDate
    HAVING 
        COUNT(t.Tag) > 1 
    ORDER BY 
        p.ViewCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
)
SELECT 
    q.QuestionId,
    q.Title,
    q.ViewCount,
    q.AnswerCount,
    q.CommentCount,
    q.CreationDate,
    q.RelatedTags,
    CAST(DATEDIFF(SECOND, q.CreationDate, '2024-10-01 12:34:56') / 86400.0 AS DECIMAL(10, 2)) AS AgeInDays
FROM 
    PopularQuestions q
ORDER BY 
    q.ViewCount DESC;
