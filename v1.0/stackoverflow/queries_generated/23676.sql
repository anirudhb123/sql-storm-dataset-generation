WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS PostCount,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        -- Calculate a user engagement score
        (COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) * 3 + 
         COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) * 2) AS EngagementScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        COALESCE(ClosedStats.ClosedCount, 0) AS ClosedCount,
        (SELECT COUNT(c.Id) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS ClosedCount 
        FROM PostHistory 
        WHERE PostHistoryTypeId IN (10, 11) -- count only closed/reopened records
        GROUP BY PostId
    ) ClosedStats ON p.Id = ClosedStats.PostId
),
VoteDistribution AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVoteCount
    FROM Votes
    GROUP BY PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    p.Title,
    p.ViewCount,
    p.Score,
    p.CommentCount,
    p.ClosedCount,
    v.UpVoteCount,
    v.DownVoteCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.EngagementScore
FROM UserStats us
JOIN PostAnalytics p ON us.UserId = p.OwnerUserId
LEFT JOIN VoteDistribution v ON p.PostId = v.PostId
WHERE us.Reputation > 1000 -- filter for higher reputation users
AND (p.Score > 0 OR p.ClosedCount > 0) -- only show successful or closed posts
OR (v.UpVoteCount - v.DownVoteCount) > 10 -- only show posts with significant positive votes
ORDER BY us.Reputation DESC, us.EngagementScore DESC, p.CreationDate DESC
LIMIT 100;
