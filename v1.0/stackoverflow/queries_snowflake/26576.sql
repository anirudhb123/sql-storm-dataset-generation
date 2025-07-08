
WITH TagUsage AS (
    SELECT 
        VALUE AS Tag,
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate
    FROM 
        Posts p,
        TABLE(FLATTEN(INPUT => SPLIT(Tags, '>')))
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
    LIMIT 10
),
PopularQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        LISTAGG(t.Tag, ', ') AS RelatedTags
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
    LIMIT 5
)
SELECT 
    q.QuestionId,
    q.Title,
    q.ViewCount,
    q.AnswerCount,
    q.CommentCount,
    q.CreationDate,
    q.RelatedTags,
    ROUND(DATEDIFF('day', q.CreationDate, '2024-10-01 12:34:56'), 2) AS AgeInDays
FROM 
    PopularQuestions q
ORDER BY 
    q.ViewCount DESC;
