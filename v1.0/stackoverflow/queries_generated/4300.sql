WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(bp.Class = 1, 0)) AS GoldBadges,
        SUM(COALESCE(bp.Class = 2, 0)) AS SilverBadges,
        SUM(COALESCE(bp.Class = 3, 0)) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges bp ON u.Id = bp.UserId
    GROUP BY u.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    RANK() OVER (ORDER BY us.TotalPosts DESC, us.Reputation DESC) AS UserRank
FROM UserStats us
LEFT JOIN RankedPosts ps ON us.UserId = ps.OwnerUserId
WHERE us.TotalPosts > 0 AND ps.Rank = 1
ORDER BY us.Reputation DESC, ps.Score DESC
LIMIT 100;
