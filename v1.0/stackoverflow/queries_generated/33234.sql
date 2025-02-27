WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Name AS BadgeName,
        b.Date AS EarnedDate
    FROM 
        Users u
    INNER JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Date >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(b.Class = 1)::int AS GoldBadges,
        SUM(b.Class = 2)::int AS SilverBadges,
        SUM(b.Class = 3)::int AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
PostHistoryStats AS (
    SELECT 
        Ph.PostId,
        COUNT(CASE WHEN Ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN Ph.PostHistoryTypeId = 24 THEN 1 END) AS SuggestedEditCount
    FROM 
        PostHistory Ph
    GROUP BY 
        Ph.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    COALESCE(b.BadgeCount, 0) AS TotalBadges,
    topU.DisplayName AS TopUserDisplayName,
    topU.Reputation AS TopUserReputation,
    phs.CloseReopenCount,
    phs.SuggestedEditCount
FROM 
    RecursivePostStats ps
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount FROM RecentBadges GROUP BY UserId) b ON ps.PostId = b.UserId
LEFT JOIN 
    (SELECT UserId, DisplayName, Reputation FROM TopUsers ORDER BY Reputation DESC LIMIT 1) topU ON ps.OwnerUserId = topU.UserId
LEFT JOIN 
    PostHistoryStats phs ON ps.PostId = phs.PostId
WHERE 
    ps.rn = 1
ORDER BY 
    ps.ViewCount DESC, 
    ps.Score DESC
LIMIT 50;
