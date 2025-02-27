WITH RecursivePostHierarchy AS (
    -- CTE to traverse the hierarchy of posts (Questions and Answers)
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.ParentId,
        P.CreationDate,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Starting with Questions
    
    UNION ALL
    
    SELECT 
        P.Id,
        P.Title,
        P.PostTypeId,
        P.ParentId,
        P.CreationDate,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy R
    ON 
        P.ParentId = R.PostId -- join to find answers for questions
)

-- Selecting various metrics including user reputation and recent activity
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(V.BountyAmount) AS TotalBounties,
    COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
    COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
    COALESCE(SUM(CASE WHEN C.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalComments,
    COALESCE(AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - P.CreationDate)) / 86400), 0) AS AvgDaysToAnswer,
    SUM(CASE WHEN R.Level > 0 THEN 1 ELSE 0 END) AS AnsweredLevel
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    RecursivePostHierarchy R ON P.Id = R.PostId
WHERE 
    U.Reputation >= 1000 -- Filtering users with high reputation
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
HAVING 
    COUNT(DISTINCT P.Id) > 10 -- Ensuring users have a significant number of posts
ORDER BY 
    TotalPosts DESC, 
    U.Reputation DESC;
