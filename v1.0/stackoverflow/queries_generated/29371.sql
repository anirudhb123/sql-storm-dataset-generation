WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY CASE 
                                              WHEN p.PostTypeId = 1 THEN 'Question'
                                              WHEN p.PostTypeId = 2 THEN 'Answer'
                                              ELSE 'Other'
                                          END ORDER BY p.Score DESC) AS Rank,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'), 1) AS TagCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  -- Filter for Questions and Answers
),
PopularQuestions AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        Score,
        ViewCount,
        TagCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 AND TagCount > 2  -- Top 10 questions with more than 2 tags
),
TopAnswersByQuestion AS (
    SELECT 
        pa.PostId AS QuestionId,
        pa.Id AS AnswerId,
        pa.OwnerUserId,
        pu.DisplayName AS AnswerOwner,
        pa.CreationDate AS AnswerDate,
        pa.Score AS AnswerScore
    FROM 
        Posts pa
    JOIN 
        Posts p ON pa.ParentId = p.Id
    JOIN 
        Users pu ON pa.OwnerUserId = pu.Id
    WHERE 
        pa.PostTypeId = 2  -- Answers
        AND p.PostTypeId = 1  -- Parent is a Question
)
SELECT 
    pq.PostId AS QuestionId,
    pq.Title AS QuestionTitle,
    pq.OwnerDisplayName AS QuestionOwner,
    pq.CreationDate AS QuestionDate,
    COUNT(ta.AnswerId) AS AnswerCount,
    COALESCE(MAX(ta.AnswerScore), 0) AS HighestAnswerScore,
    AVG(ta.AnswerScore) AS AvgAnswerScore
FROM 
    PopularQuestions pq
LEFT JOIN 
    TopAnswersByQuestion ta ON pq.PostId = ta.QuestionId
GROUP BY 
    pq.PostId, pq.Title, pq.OwnerDisplayName, pq.CreationDate
ORDER BY 
    pq.Score DESC;
