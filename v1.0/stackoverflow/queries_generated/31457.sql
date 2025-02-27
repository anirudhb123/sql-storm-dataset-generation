WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.AcceptedAnswerId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.ViewCount,
        a.Score,
        a.CreationDate,
        a.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id  -- Answers to Questions
    WHERE 
        q.PostTypeId = 1
)
, PostScores AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.Score,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS VoteScore,  -- Accumulate Upvotes and Downvotes
        RANK() OVER (PARTITION BY CASE WHEN p.PostTypeId = 1 THEN 'Question' ELSE 'Answer' END ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.Score
)
, UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.Views) AS TotalPostViews 
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.ViewCount,
    ph.Score,
    ps.VoteScore,
    ps.Rank,
    CASE 
        WHEN u.Reputation IS NULL THEN 'No Reputation'
        ELSE 'Reputation: ' || u.Reputation
    END AS ReputationInfo,
    u.BadgeCount AS UserBadges,
    u.TotalPostViews AS UserTotalViews
FROM 
    RecursivePostHierarchy ph
LEFT JOIN 
    PostScores ps ON ph.PostId = ps.Id
LEFT JOIN 
    UserReputation u ON ps.OwnerUserId = u.UserId
WHERE 
    ph.Level < 3  -- Limit depth for performance benchmarking
ORDER BY 
    ph.Level, ps.Rank
OPTION (MAXRECURSION 100);
