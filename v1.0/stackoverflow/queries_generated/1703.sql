WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        ROUND(AVG(p.Score), 2) AS AvgPostScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),

BadgesGranted AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),

CombinedStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.AnswerCount,
        us.QuestionCount,
        us.AvgPostScore,
        COALESCE(bg.TotalBadges, 0) AS TotalBadges,
        COALESCE(bg.GoldBadges, 0) AS GoldBadges,
        COALESCE(bg.SilverBadges, 0) AS SilverBadges,
        COALESCE(bg.BronzeBadges, 0) AS BronzeBadges
    FROM UserStats us
    LEFT JOIN BadgesGranted bg ON us.UserId = bg.UserId
)

SELECT 
    cs.DisplayName,
    cs.Reputation,
    cs.PostCount,
    cs.AnswerCount,
    cs.QuestionCount,
    cs.AvgPostScore,
    cs.TotalBadges,
    cs.GoldBadges,
    cs.SilverBadges,
    cs.BronzeBadges
FROM CombinedStats cs
WHERE cs.Reputation > 1000
ORDER BY cs.Reputation DESC, cs.PostCount DESC
LIMIT 10;

WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
),

PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Body,
        rp.Score,
        rp.ViewCount,
        u.DisplayName,
        COUNT(cm.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM RecentPosts rp
    LEFT JOIN Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN Comments cm ON rp.PostId = cm.PostId
    LEFT JOIN Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 8
    GROUP BY rp.PostId, rp.Title, rp.CreationDate, rp.Body, rp.Score, rp.ViewCount, u.DisplayName
)

SELECT 
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.DisplayName,
    pm.CommentCount,
    COALESCE(pm.TotalBounty, 0) AS TotalBounty
FROM PostMetrics pm
WHERE pm.ViewCount > 100
ORDER BY pm.Score DESC, pm.ViewCount DESC;
