
WITH TagFrequency AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS Frequency
    FROM 
        Posts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        Frequency,
        @rownum := @rownum + 1 AS Rank
    FROM 
        TagFrequency, (SELECT @rownum := 0) r
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
        TopTags t ON FIND_IN_SET(t.Tag, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) > 0
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
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
    GROUP_CONCAT(DISTINCT pq.Tag ORDER BY pq.Tag SEPARATOR ', ') AS Tags
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
