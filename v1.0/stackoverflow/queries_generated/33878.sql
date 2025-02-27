WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        CAST(u.Reputation AS BIGINT) AS TotalReputation,
        1 AS Level
    FROM Users u
    WHERE u.Reputation > 1000

    UNION ALL

    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        CAST(ur.TotalReputation + u.Reputation AS BIGINT),
        Level + 1
    FROM Users u
    JOIN UserReputationCTE ur ON u.Id != ur.UserId
    WHERE ur.Level < 5 AND u.Reputation > 1000
),

TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.Score > 0
),

PostSummary AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE p.PostTypeId = 1 -- Questions only
    GROUP BY p.Id, u.DisplayName
),

UserActivity AS (
    SELECT 
        ur.UserId,
        ur.TotalReputation,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY ur.UserId ORDER BY ps.CreationDate DESC) AS RecentActivityRank
    FROM UserReputationCTE ur
    JOIN PostSummary ps ON ur.UserId = ps.OwnerDisplayName 
)

SELECT 
    u.DisplayName,
    u.Reputation,
    ur.TotalReputation,
    ps.Title AS RecentPostTitle,
    ps.CreationDate AS RecentPostDate,
    ps.CommentCount,
    ua.RecentActivityRank
FROM Users u
JOIN UserReputationCTE ur ON u.Id = ur.UserId
LEFT JOIN PostSummary ps ON u.Id = ps.OwnerDisplayName AND ps.AcceptedAnswerId = 0 -- No accepted answer
LEFT JOIN UserActivity ua ON u.Id = ua.UserId AND ua.RecentActivityRank = 1
ORDER BY u.Reputation DESC, ur.TotalReputation DESC 
LIMIT 100;

