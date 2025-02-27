WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostMetrics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.Score) AS AverageScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserActivity AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        COALESCE(pm.PostCount, 0) AS PostCount,
        COALESCE(pm.Questions, 0) AS Questions,
        COALESCE(pm.Answers, 0) AS Answers,
        COALESCE(pm.AverageScore, 0) AS AverageScore,
        (CURRENT_TIMESTAMP - us.CreationDate) AS AccountAge,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges
    FROM 
        UserStats us
    LEFT JOIN 
        PostMetrics pm ON us.UserId = pm.OwnerUserId
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.PostCount,
    ua.Questions,
    ua.Answers,
    ua.AverageScore,
    ua.AccountAge,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    CASE 
        WHEN ua.Reputation > 1000 THEN 'Pro User'
        WHEN ua.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate User'
        ELSE 'New User'
    END AS UserLevel
FROM 
    UserActivity ua
WHERE 
    ua.PostCount > 0 OR ua.GoldBadges > 0
ORDER BY 
    ua.Reputation DESC
LIMIT 10;

-- Get the last 5 distinct close reasons used for closed posts
SELECT DISTINCT 
    ch.Comment AS CloseReason
FROM 
    PostHistory ph
JOIN 
    CloseReasonTypes ch ON ph.Comment = CAST(ch.Id AS VARCHAR)
WHERE 
    ph.PostHistoryTypeId = 10
ORDER BY 
    ph.CreationDate DESC
LIMIT 5;

-- Aggregate data to check the votes received by the top users
SELECT 
    u.DisplayName,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            ELSE 0 
        END) AS UpVotes,
    SUM(CASE 
            WHEN v.VoteTypeId = 3 THEN 1 
            ELSE 0 
        END) AS DownVotes
FROM 
    Users u
LEFT JOIN 
    Votes v ON u.Id = v.UserId
GROUP BY 
    u.Id
HAVING 
    COUNT(v.Id) > 5
ORDER BY 
    VoteCount DESC
LIMIT 10;
