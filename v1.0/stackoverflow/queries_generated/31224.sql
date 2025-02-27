WITH RECURSIVE UserReputation AS (
    SELECT 
        Id, 
        Reputation, 
        CreationDate, 
        1 AS Level
    FROM Users 
    WHERE Reputation > 1000

    UNION ALL 

    SELECT 
        u.Id, 
        u.Reputation, 
        u.CreationDate, 
        ur.Level + 1
    FROM Users u
    JOIN UserReputation ur ON u.Reputation > (ur.Reputation * 0.5) AND u.Id != ur.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM Posts p
    WHERE p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId, 
        COUNT(v.Id) FILTER(WHERE v.VoteTypeId IN (2, 3)) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    COUNT(DISTINCT rp.PostId) AS RecentPostCount,
    MAX(rp.CreationDate) AS LastPostDate,
    SUM(pvs.UpVotes) AS TotalUpVotes,
    SUM(pvs.DownVotes) AS TotalDownVotes,
    (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = u.Id) AS TotalPosts
FROM Users u
LEFT JOIN RecentPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PostVoteStats pvs ON pvs.PostId IN (SELECT r.PostId FROM RecentPosts r WHERE r.OwnerUserId = u.Id)
GROUP BY u.Id, u.DisplayName, u.Reputation, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
HAVING COUNT(DISTINCT rp.PostId) > 0
ORDER BY u.Reputation DESC
LIMIT 10;
