WITH UserBadgeSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AverageViewCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
TopUsersByBadges AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.TotalBadges,
        ps.PostCount,
        ps.TotalScore,
        ps.AverageViewCount,
        ROW_NUMBER() OVER (ORDER BY u.TotalBadges DESC, ps.TotalScore DESC) AS BadgeRank
    FROM 
        UserBadgeSummary u
    JOIN 
        PostStatistics ps ON u.UserId = ps.OwnerUserId
)
SELECT
    u.UserId,
    u.DisplayName,
    COALESCE(u.TotalBadges, 0) AS TotalBadges,
    COALESCE(ps.PostCount, 0) AS PostCount,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    ROUND(COALESCE(AverageViewCount, 0) , 2) AS AverageViewCount,
    u.BadgeRank
FROM 
    TopUsersByBadges u
LEFT JOIN 
    PostStatistics ps ON u.UserId = ps.OwnerUserId
WHERE 
    COALESCE(u.TotalBadges, 0) > 0
ORDER BY 
    BadgeRank DESC, u.TotalBadges DESC
LIMIT 10;

WITH RECURSIVE BadgeDistribution AS (
    SELECT 
        UserId,
        COUNT(*) as BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
UnassignedBadges AS (
    SELECT
        bt.Id,
        bt.Name,
        COUNT(b.UserId) AS UsersAssigned
    FROM 
        PostHistoryTypes bt
    LEFT JOIN 
        Badges b ON bt.Id = b.Id
    WHERE 
        b.UserId IS NULL OR b.UserId NOT IN (SELECT UserId FROM BadgeDistribution)
    GROUP BY 
        bt.Id, bt.Name
)
SELECT 
    bt.Name AS UnassignedBadge,
    COALESCE(u.UsersAssigned, 0) AS UsersCurrentlyAssigned
FROM 
    UnassignedBadges u
JOIN 
    PostHistoryTypes bt ON u.Id = bt.Id
ORDER BY 
    UsersAssigned ASC NULLS LAST;

SELECT DISTINCT 
    p.OwnerUserId,
    u.DisplayName,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL 
             THEN 1 ELSE 0 END) AS AcceptedAnswers,
    COUNT(DISTINCT c.Id) AS CommentCount,
    AVG(p.Score) as AverageScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TaggedWith
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostsTags pt ON p.Id = pt.PostId
LEFT JOIN 
    Tags t ON pt.TagId = t.Id
WHERE 
    p.CreationDate BETWEEN NOW() - INTERVAL '6 months' AND NOW()
GROUP BY 
    p.OwnerUserId, u.DisplayName
HAVING 
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    AverageScore DESC;
