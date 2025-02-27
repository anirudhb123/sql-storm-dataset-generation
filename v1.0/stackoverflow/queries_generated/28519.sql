WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),

TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),

QuestionsWithAnswers AS (
    SELECT 
        tq.PostId,
        tq.Title,
        tq.OwnerDisplayName,
        tq.ViewCount,
        tq.Score,
        COUNT(a.Id) AS AnswerCount
    FROM 
        TopQuestions tq
    LEFT JOIN 
        Posts a ON tq.PostId = a.ParentId AND a.PostTypeId = 2 -- Answers
    GROUP BY 
        tq.PostId, tq.Title, tq.OwnerDisplayName, tq.ViewCount, tq.Score
)

SELECT 
    q.Title,
    q.OwnerDisplayName,
    q.ViewCount,
    q.Score,
    q.AnswerCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    QuestionsWithAnswers q 
LEFT JOIN 
    Posts p ON q.PostId = p.Id
LEFT JOIN 
    String_to_array(p.Tags, ', ') AS sp ON TRUE 
LEFT JOIN 
    Tags t ON t.TagName = trim(BOTH '>' FROM trim(BOTH '<' FROM sp))
GROUP BY 
    q.PostId, q.Title, q.OwnerDisplayName, q.ViewCount, q.Score
ORDER BY 
    q.Score DESC;

This SQL query performs several tasks:

1. **RankedPosts** CTE: Retrieves questions from the past year and ranks them based on score within their tags.
2. **TopQuestions** CTE: Selects the top 5 ranked questions for each tag.
3. **QuestionsWithAnswers** CTE: Computes the number of answers for each top question.
4. Final Selection: It lists the relevant details of the top questions including their tags using string aggregation. 

This approach benchmarks string processing by handling tags and provides insights into the performance of top questions in terms of views, scores, and answers.
