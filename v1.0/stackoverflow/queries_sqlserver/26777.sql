
WITH TagFrequency AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS Frequency
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        Tag,
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS Rank
    FROM 
        TagFrequency
    WHERE 
        Frequency > 1 
),
PopularQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        p.Tags,
        t.Tag
    FROM 
        Posts p
    JOIN 
        TopTags t ON t.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><'))
    WHERE 
        p.PostTypeId = 1
)
SELECT 
    pq.QuestionId,
    pq.Title,
    pq.ViewCount,
    pq.AnswerCount,
    pq.CreationDate,
    STRING_AGG(DISTINCT pq.Tag, ', ') AS Tags
FROM 
    PopularQuestions pq
GROUP BY 
    pq.QuestionId, 
    pq.Title, 
    pq.ViewCount, 
    pq.AnswerCount, 
    pq.CreationDate
ORDER BY 
    pq.ViewCount DESC;
