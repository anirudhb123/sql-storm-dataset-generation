WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId IN (1, 2) -- Only questions and answers
    GROUP BY p.Id, p.Title, p.PostTypeId, p.CreationDate, p.OwnerUserId, p.Score, p.ViewCount
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        MAX(p.LastActivityDate) AS LastActivity,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS TotalUpvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS TotalDownvotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(r.LastActivity, '1970-01-01') AS LastActivity,
        r.TotalUpvotes,
        r.TotalDownvotes,
        RANK() OVER (ORDER BY COALESCE(u.Reputation, 0) DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN RecentActivity r ON u.Id = r.OwnerUserId
    WHERE u.Reputation IS NOT NULL
),
LowPerformingUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation
    FROM UserReputation ur
    WHERE ur.Reputation < 100
)
SELECT 
    up.ReputationRank,
    up.DisplayName,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(rp.Score) AS TotalScore,
    COALESCE(SUM(rp.ViewCount), 0) AS TotalViews,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rp.Score) AS MedianScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM LowPerformingUsers up
JOIN Posts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN Comments c ON rp.Id = c.PostId
LEFT JOIN Votes v ON rp.Id = v.PostId
LEFT JOIN unnest(string_to_array(rp.Tags, '><')) AS t(TagName) ON TRUE
GROUP BY up.UserId, up.DisplayName, up.ReputationRank
HAVING COUNT(DISTINCT rp.PostId) > 5
ORDER BY up.ReputationRank ASC;
