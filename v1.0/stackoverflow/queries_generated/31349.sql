WITH RECURSIVE UserReputation AS (
    -- CTE to calculate the reputation score over time for users
    SELECT 
        Id, 
        Reputation, 
        CreationDate,
        LastAccessDate,
        DisplayName,
        ROW_NUMBER() OVER (PARTITION BY Id ORDER BY CreationDate DESC) AS rank
    FROM 
        Users
),
PostEngagement AS (
    -- CTE to aggregate post details including comments and votes
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(vc.VoteCount, 0) AS VoteCount,
        COALESCE(v.SumScore, 0) AS TotalScore,
        UTC_TIMESTAMP() - p.CreationDate AS AgeInSeconds
    FROM 
        Posts p
    LEFT JOIN (
        -- Count comments for each post
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) pc ON p.Id = pc.PostId
    LEFT JOIN (
        -- Count votes for each post
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS SumScore 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) vc ON p.Id = vc.PostId
),
UserBadges AS (
    -- CTE to find users with specific badges
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeList
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges only
    GROUP BY 
        b.UserId
)
-- Main query to benchmark performance
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    ur.Reputation AS LastKnownReputation,
    pe.PostId,
    pe.Title,
    pe.CommentCount,
    pe.VoteCount,
    pe.TotalScore,
    ub.BadgeCount,
    ub.BadgeList
FROM 
    Users u
JOIN UserReputation ur ON u.Id = ur.Id AND ur.rank = 1
LEFT JOIN PostEngagement pe ON u.Id = pe.Title 
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users) -- Users with above-average reputation
ORDER BY 
    u.Reputation DESC,
    pe.TotalScore DESC
LIMIT 100; -- Limit to top 100 users by reputation
