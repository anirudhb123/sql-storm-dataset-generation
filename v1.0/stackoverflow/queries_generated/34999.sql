WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)
, UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9) -- Bounty Start and Bounty Close
    GROUP BY 
        u.Id
)
, QuestionStats AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        COUNT(a.Id) AS AnswerCount,
        MAX(p.CreationDate) AS CreationDate,
        UPPER(TRIM(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags)-2))) AS Tags -- Extract tags
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId 
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        p.Id
)
SELECT 
    qs.QuestionId,
    qs.Title,
    qs.AnswerCount,
    CONCAT(u.DisplayName, ' (Reput: ', u.Reputation, ', Bounties: ', u.TotalBounties, ')') AS UserInfo,
    ph.Level,
    qs.Tags
FROM 
    QuestionStats qs
JOIN 
    Posts p ON p.Id = qs.QuestionId
JOIN 
    Users u ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHierarchy ph ON ph.PostId = qs.QuestionId
WHERE 
    qs.AnswerCount > 0 -- Only include questions with answers
    AND u.Reputation > 1000 -- Only includes users with more than 1000 reputation
ORDER BY 
    qs.AnswerCount DESC, 
    ph.Level ASC, 
    qs.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY; -- Pagination
