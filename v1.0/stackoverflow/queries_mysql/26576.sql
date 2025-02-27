
WITH TagUsage AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', n.n), '>', -1) AS Tag,
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate
    FROM 
        Posts p
    JOIN (
        SELECT 
            1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
            UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= n.n - 1
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
        GROUP_CONCAT(t.Tag ORDER BY t.Tag SEPARATOR ', ') AS RelatedTags
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
    ROUND(TIMESTAMPDIFF(SECOND, q.CreationDate, '2024-10-01 12:34:56') / 86400, 2) AS AgeInDays
FROM 
    PopularQuestions q
ORDER BY 
    q.ViewCount DESC;
