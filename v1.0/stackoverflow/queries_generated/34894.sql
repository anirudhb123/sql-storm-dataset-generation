WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Start with top-level posts

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),

PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- We're only interested in questions
    GROUP BY 
        p.Id, p.Title
),

BadgesEarned AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        b.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        BadgesEarned b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100  -- Only considering users with a reputation greater than 100
)

SELECT 
    ps.Title AS QuestionTitle,
    ps.AnswerCount,
    ps.TotalBounty,
    ps.UpVotes,
    ps.DownVotes,
    pu.DisplayName AS TopUser,
    pu.Reputation AS UserReputation,
    pu.BadgeCount AS UserBadgeCount,
    COALESCE(rh.Level, 0) AS PostLevel
FROM 
    PostStats ps
LEFT JOIN 
    TopUsers pu ON ps.Id = (SELECT ParentId FROM Posts WHERE Id = ps.Id)
LEFT JOIN 
    RecursivePostHierarchy rh ON ps.Id = rh.Id
WHERE 
    ps.UpVotes > ps.DownVotes  -- Only include questions with more upvotes than downvotes
ORDER BY 
    ps.UpVotes DESC,
    ps.AnswerCount DESC
LIMIT 10;

-- Checking for users who might not have badges but are still prominent based on their reputation
SELECT 
    u.DisplayName,
    u.Reputation,
    CASE 
        WHEN b.BadgeCount IS NULL THEN 'No Badges'
        ELSE 'Has Badges'
    END AS BadgeStatus
FROM 
    Users u
LEFT JOIN 
    BadgesEarned b ON u.Id = b.UserId
WHERE 
    u.Reputation > 500
ORDER BY 
    u.Reputation DESC
LIMIT 5;
