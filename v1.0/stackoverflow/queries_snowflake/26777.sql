
WITH TagFrequency AS (
    SELECT 
        TRIM(value) AS Tag,
        COUNT(*) AS Frequency
    FROM 
        Posts,
        LATERAL FLATTEN(input => SPLIT(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS value
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(value)
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
        TopTags t ON t.Tag IN (SELECT TRIM(value) FROM LATERAL FLATTEN(input => SPLIT(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS value)
    WHERE 
        p.PostTypeId = 1
    ORDER BY 
        p.ViewCount DESC
    LIMIT 10
)
SELECT 
    pq.QuestionId,
    pq.Title,
    pq.ViewCount,
    pq.AnswerCount,
    pq.CreationDate,
    LISTAGG(DISTINCT pq.Tag, ', ') AS Tags
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
