WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Questions only
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostClosureCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ClosureCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY ph.PostId
),
UserPostDetails AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(SUM(pc.ClosureCount), 0) AS TotalClosedPosts,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM Users u
    LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN PostClosureCounts pc ON pc.PostId = rp.PostId
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    WHERE u.Reputation > 500 -- Filter users with a reputation greater than 500
    GROUP BY u.DisplayName, u.Reputation
)
SELECT 
    ud.DisplayName,
    ud.Reputation,
    ud.TotalScore,
    ud.TotalClosedPosts,
    CASE 
        WHEN ud.TotalPosts > 0 THEN ROUND((ud.TotalScore::DECIMAL / ud.TotalPosts), 2) 
        ELSE NULL 
    END AS AvgScorePerPost,
    COALESCE(SUM(CASE WHEN ur.GoldBadges > 0 THEN 1 ELSE 0 END), 0) AS GoldBadgeOwners
FROM UserPostDetails ud
LEFT JOIN UserReputation ur ON ud.UserId = ur.UserId
GROUP BY ud.DisplayName, ud.Reputation, ud.TotalScore, ud.TotalClosedPosts
ORDER BY ud.Reputation DESC, AvgScorePerPost DESC
LIMIT 10;
