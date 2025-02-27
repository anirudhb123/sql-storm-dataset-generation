WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only Questions 
        AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Within the last year
),

TagStatistics AS (
    SELECT 
        Tags,
        COUNT(*) AS QuestionCount,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(CommentCount) AS TotalComments,
        AVG(Score) AS AvgScore
    FROM 
        RankedPosts
    GROUP BY 
        Tags
),

TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        ts.Tags,
        ts.QuestionCount,
        ts.TotalAnswers,
        ts.TotalComments,
        ts.AvgScore
    FROM 
        RankedPosts rp
    JOIN 
        TagStatistics ts ON rp.Tags = ts.Tags
    WHERE 
        rp.TagRank <= 5  -- Selecting top 5 ranked posts per tag
)

SELECT 
    tq.Title,
    tq.CreationDate,
    tq.Tags,
    tq.QuestionCount,
    tq.TotalAnswers,
    tq.TotalComments,
    tq.AvgScore,
    u.DisplayName AS OwnerDisplayName
FROM 
    TopQuestions tq
JOIN 
    Users u ON tq.OwnerUserId = u.Id
ORDER BY 
    tq.AvgScore DESC, 
    tq.CreationDate DESC
LIMIT 10;  -- Limiting to top 10 questions based on average score
