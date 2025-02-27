WITH RecursivePostHierarchy AS (
    -- CTE to recursively find all answers for each question
    SELECT 
        p.Id AS PostId,
        p.AcceptedAnswerId AS AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        p.Id,
        p.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
    WHERE 
        p.PostTypeId = 2  -- Only answers
),
PostVoteStats AS (
    -- CTE to aggregate vote statistics for posts
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadgeCounts AS (
    -- CTE to count badges for each user
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostActivity AS (
    -- CTE to find most recent activity for posts
    SELECT 
        p.Id AS PostId,
        p.LastActivityDate,
        p.OwnerUserId,
        COALESCE(u.Reputation, 0) AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
)
SELECT 
    ph.PostId,
    p.Title,
    p.Body,
    pa.LastActivityDate,
    pa.OwnerReputation,
    COALESCE(ps.Upvotes, 0) AS Upvotes,
    COALESCE(ps.Downvotes, 0) AS Downvotes,
    (COALESCE(ps.Upvotes, 0) - COALESCE(ps.Downvotes, 0)) AS VoteScore,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    COUNT(NULLIF(ph.AcceptedAnswerId, -1)) AS AcceptedAnswers
FROM 
    RecursivePostHierarchy ph
JOIN 
    Posts p ON p.Id = ph.PostId
LEFT JOIN 
    PostVoteStats ps ON ps.PostId = p.Id
LEFT JOIN 
    UserBadgeCounts ub ON ub.UserId = p.OwnerUserId
JOIN 
    PostActivity pa ON pa.PostId = p.Id
WHERE 
    pa.LastActivityDate > CURRENT_DATE - INTERVAL '30 days' -- Filter for recent activity
GROUP BY 
    ph.PostId, p.Title, p.Body, pa.LastActivityDate, pa.OwnerReputation, ps.Upvotes, ps.Downvotes, ub.BadgeCount
ORDER BY 
    VoteScore DESC
LIMIT 100;
