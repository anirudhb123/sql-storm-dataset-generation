WITH UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN ub.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN ub.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN ub.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges ub
    GROUP BY ub.UserId
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    rp.PostId,
    rp.Title AS RecentTitle,
    rp.CreationDate AS RecentCreationDate
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
WHERE u.Reputation > 1000
ORDER BY u.Reputation DESC, RecentCreationDate DESC
FETCH FIRST 10 ROWS ONLY;

WITH PostScore AS (
    SELECT 
        p.Id,
        (COALESCE(p.Score, 0) + COALESCE(vup.UpVotes, 0) - COALESCE(vdown.DownVotes, 0)) AS NetScore,
        p.Title,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS UpVotes
        FROM Votes
        WHERE VoteTypeId = 2
        GROUP BY PostId
    ) vup ON p.Id = vup.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS DownVotes
        FROM Votes
        WHERE VoteTypeId = 3
        GROUP BY PostId
    ) vdown ON p.Id = vdown.PostId
)
SELECT 
    ps.Id AS PostId,
    ps.Title,
    ps.NetScore,
    COALESCE(user.DisplayName, 'Anonymous') AS Owner,
    ROW_NUMBER() OVER (ORDER BY ps.NetScore DESC) AS ScoreRank
FROM PostScore ps
LEFT JOIN Users user ON ps.OwnerUserId = user.Id
WHERE ps.NetScore > 0
ORDER BY ps.NetScore DESC
FETCH FIRST 5 ROWS ONLY;
