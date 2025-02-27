WITH RecursivePostHierarchy AS (
    -- CTE to get posts and their answers recursively
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.AcceptedAnswerId,
        COALESCE(a.Score, 0) AS AcceptScore,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1  -- Questions only
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.AcceptedAnswerId,
        COALESCE(a.Score, 0) AS AcceptScore,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
UserPostVotes AS (
    -- CTE to aggregate user votes on posts
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserBadges AS (
    -- CTE to get user badges along with their user reputation
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    rph.PostId,
    rph.Title,
    rph.AcceptScore,
    rph.CreationDate,
    COALESCE(upv.TotalUpVotes, 0) AS UpVotes,
    COALESCE(upv.TotalDownVotes, 0) AS DownVotes,
    ub.Reputation AS UserReputation,
    ub.BadgeCount AS UserBadgeCount,
    CASE 
        WHEN rph.AcceptScore > 0 THEN 'Accepted Answer'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus
FROM 
    RecursivePostHierarchy rph
LEFT JOIN 
    UserPostVotes upv ON rph.PostId = upv.PostId
LEFT JOIN 
    Posts p ON rph.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rph.Level = 1 -- Only top-level questions
ORDER BY 
    rph.CreationDate DESC, 
    rph.AcceptScore DESC
LIMIT 100; -- Limit to the most recent 100 questions
