WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.ViewCount IS NOT NULL
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        MAX(u.LastAccessDate) AS LastActiveDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(c.Score, 0) AS CommentScore
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS CommentCount, 
            SUM(Score) AS Score 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    us.PostCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    pwc.CommentCount,
    pwc.CommentScore,
    CASE 
        WHEN u.Reputation > 1000 THEN 'High Reputation User' 
        ELSE 'Regular User' 
    END AS UserCategory,
    CASE 
        WHEN pwc.CommentCount > 10 THEN 'Active Commenter' 
        ELSE 'Lurker' 
    END AS UserActivity
FROM 
    UserStats us
JOIN 
    Users u ON us.UserId = u.Id
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    PostsWithComments pwc ON rp.PostId = pwc.PostId
WHERE 
    us.BadgeCount > 0
    AND (us.LastActiveDate IS NULL OR us.LastActiveDate >= NOW() - INTERVAL '30 days')
ORDER BY 
    u.Reputation DESC, rp.Score DESC
LIMIT 100;

-- Test for peculiar cases that might break normal expectations:
-- 1. Fetch users who have no badges yet posted answers (Outer join and NULL test)
-- 2. Concatenate User information with potential NULL handling
WITH UserAnswers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    COALESCE(ua.AnswerCount, 0) AS AnswerCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    UserAnswers ua
LEFT JOIN 
    (SELECT UserId, COUNT(Id) AS BadgeCount FROM Badges GROUP BY UserId) b ON ua.UserId = b.UserId
WHERE 
    ua.AnswerCount > 0
    OR b.BadgeCount IS NULL
ORDER BY 
    ua.AnswerCount DESC;
