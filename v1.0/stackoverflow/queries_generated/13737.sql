-- Performance benchmarking query for the Stack Overflow schema

-- Measure the average response time to answer questions based on the number of views and scores
SELECT 
    P.Title AS QuestionTitle,
    P.CreationDate AS QuestionDate,
    P.ViewCount AS NumberOfViews,
    P.Score AS QuestionScore,
    A.CreationDate AS AnswerDate,
    EXTRACT(EPOCH FROM (A.CreationDate - P.CreationDate)) AS ResponseTimeInSeconds,
    A.Score AS AnswerScore,
    U.DisplayName AS AnswererDisplayName
FROM 
    Posts P
JOIN 
    Posts A ON P.Id = A.ParentId
JOIN 
    Users U ON A.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 -- Questions
    AND A.PostTypeId = 2 -- Answers
ORDER BY 
    ResponseTimeInSeconds;

-- Measure the number of posts created over time to assess activity trends
SELECT 
    DATE_TRUNC('month', CreationDate) AS Month,
    COUNT(*) AS PostsCreated
FROM 
    Posts
GROUP BY 
    Month
ORDER BY 
    Month;

-- Measure the distribution of votes on posts
SELECT 
    V.VoteTypeId,
    COUNT(*) AS VoteCount
FROM 
    Votes V
JOIN 
    Posts P ON V.PostId = P.Id
GROUP BY 
    V.VoteTypeId
ORDER BY 
    VoteCount DESC;

-- Measure the average reputation of users who answered questions
SELECT 
    U.Reputation AS UserReputation,
    COUNT(A.Id) AS NumberOfAnswers
FROM 
    Posts P
JOIN 
    Posts A ON P.Id = A.ParentId
JOIN 
    Users U ON A.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 -- Questions
    AND A.PostTypeId = 2 -- Answers
GROUP BY 
    U.Reputation
ORDER BY 
    UserReputation DESC;

-- Measure the relationship between question scores and the number of answers
SELECT 
    P.Score AS QuestionScore,
    COUNT(A.Id) AS NumberOfAnswers
FROM 
    Posts P
LEFT JOIN 
    Posts A ON P.Id = A.ParentId
WHERE 
    P.PostTypeId = 1 -- Questions
GROUP BY 
    P.Score
ORDER BY 
    QuestionScore DESC;
