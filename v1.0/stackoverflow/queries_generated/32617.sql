WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        Posts a ON p.ParentId = a.Id
    WHERE 
        a.PostTypeId = 1 -- Only questions
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT p2.Id) AS AnswerCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(c.CreationDate) AS LastCommentDate,
    COUNT(DISTINCT c.Id) AS CommentCount,
    AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgPostLifetimeInSeconds,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(v.CreationDate) DESC) AS UserActivityLevel
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId -- User's posts
LEFT JOIN 
    Posts p2 ON p.AcceptedAnswerId = p2.Id -- Accepted answers
LEFT JOIN 
    Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%') -- Tag matching
LEFT JOIN 
    Comments c ON c.PostId = p.Id -- User's comments
LEFT JOIN 
    Votes v ON v.PostId = p.Id -- User's votes
WHERE 
    u.Reputation > 1000 AND -- Consider users with reputation greater than 1000
    u.LastAccessDate >= NOW() - INTERVAL '1 year' -- Active users in the last year
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 5 -- Users with more than 5 posts
ORDER BY 
    TotalUpVotes DESC, AvgPostLifetimeInSeconds ASC;

-- Performance benchmarking considerations:
-- 1. RecursiveCTE demonstrates the hierarchy of questions and answers.
-- 2. COALESCE handles NULL values for votes.
-- 3. STRING_AGG aggregates tags for easy overview.
-- 4. WINDOW functions like ROW_NUMBER provide insights into user activity levels.
