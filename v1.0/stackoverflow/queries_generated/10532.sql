-- Performance benchmarking query for Stack Overflow schema

-- Retrieve the average score and view count of questions along with user reputation
WITH QuestionStats AS (
    SELECT 
        p.Id AS QuestionId,
        p.Score AS QuestionScore,
        p.ViewCount AS QuestionViews,
        u.Reputation AS UserReputation
    FROM 
        Posts AS p
    JOIN 
        Users AS u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
)

-- Calculate total and average metrics
SELECT 
    COUNT(*) AS TotalQuestions,
    AVG(QuestionScore) AS AverageScore,
    AVG(QuestionViews) AS AverageViews,
    AVG(UserReputation) AS AverageUserReputation
FROM 
    QuestionStats;

-- Additionally, retrieve the total number of answers and their average score
WITH AnswerStats AS (
    SELECT 
        p.Id AS AnswerId,
        p.Score AS AnswerScore,
        u.Reputation AS UserReputation
    FROM 
        Posts AS p
    JOIN 
        Users AS u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 2  -- Only answers
)

SELECT 
    COUNT(*) AS TotalAnswers,
    AVG(AnswerScore) AS AverageAnswerScore,
    AVG(UserReputation) AS AverageAnswerUserReputation
FROM 
    AnswerStats;

-- Benchmarking on PostHistory for closed posts
WITH ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ClosureCount
    FROM 
        PostHistory AS ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Closed posts
    GROUP BY 
        ph.PostId
)

SELECT 
    COUNT(*) AS TotalClosedPosts,
    AVG(ClosureCount) AS AverageClosuresPerPost
FROM 
    ClosedPosts;

-- Final query to analyze the most common close reasons
SELECT 
    ph.Comment AS CloseReason,
    COUNT(*) AS ReasonCount
FROM 
    PostHistory AS ph
WHERE 
    ph.PostHistoryTypeId = 10  -- Closed posts
GROUP BY 
    ph.Comment
ORDER BY 
    ReasonCount DESC
LIMIT 10;
