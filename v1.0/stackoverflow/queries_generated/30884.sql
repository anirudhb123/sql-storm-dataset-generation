WITH RecursivePostPaths AS (
    -- Recursive CTE to find all answers and their respective questions
    SELECT 
        p.Id AS PostId,
        p.Title AS QuestionTitle,
        p.OwnerUserId AS OwnerId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        q.Title AS QuestionTitle,
        a.OwnerUserId AS OwnerId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id
    WHERE 
        a.PostTypeId = 2  -- Answers
)
, UserReputation AS (
    -- CTE to calculate total reputation for users based on their posts and votes
    SELECT 
        u.Id AS UserId,
        u.Reputation + COALESCE(SUM(v.BountyAmount), 0) AS TotalReputation
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
QuestionStatistics AS (
    -- CTE to gather statistics for the questions
    SELECT 
        p.Id AS QuestionId,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        MAX(a.CreationDate) AS LatestAnswerDate,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2  -- Answers
    LEFT JOIN 
        Comments c ON c.PostId = p.Id  -- Comments
    WHERE 
        p.PostTypeId = 1  -- Questions
    GROUP BY 
        p.Id
)
SELECT 
    pp.PostId,
    pp.QuestionTitle,
    u.DisplayName AS OwnerDisplayName,
    ur.TotalReputation AS OwnerReputation,
    qs.AnswerCount,
    qs.LatestAnswerDate,
    qs.CommentCount,
    CASE 
        WHEN qs.LatestAnswerDate IS NULL THEN 'No Answers Yet'
        ELSE 'Answers Available'
    END AS AnswerStatus
FROM 
    RecursivePostPaths pp
JOIN 
    Users u ON pp.OwnerId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
JOIN 
    QuestionStatistics qs ON pp.PostId = qs.QuestionId
ORDER BY 
    ur.TotalReputation DESC, 
    qs.LatestAnswerDate DESC
LIMIT 50;  -- Limit to top 50 high-reputation users' questions
