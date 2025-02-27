
WITH RecentPostStats AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), NULL) AS AcceptedAnswer,
        COUNT(DISTINCT c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AcceptedAnswerId, p.OwnerUserId
),

UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),

PostHistoryWithComments AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS CloseReopenHistory,
        GROUP_CONCAT(DISTINCT c.Text SEPARATOR '; ') AS CommentTexts
    FROM 
        PostHistory ph
    LEFT JOIN 
        Comments c ON ph.PostId = c.PostId
    GROUP BY 
        ph.PostId
)

SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    rs.Reputation,
    rs.DisplayName,
    COALESCE(rs.BadgeCount, 0) AS BadgeCount,
    COALESCE(rs.GoldBadges, 0) AS GoldBadges,
    COALESCE(rs.SilverBadges, 0) AS SilverBadges,
    COALESCE(rs.BronzeBadges, 0) AS BronzeBadges,
    ph.CloseReopenHistory,
    ph.CommentTexts
FROM 
    RecentPostStats p
JOIN 
    UserReputation rs ON p.OwnerUserId = rs.UserId
LEFT JOIN 
    PostHistoryWithComments ph ON p.PostId = ph.PostId
WHERE 
    (p.UserPostRank <= 5 OR ph.CloseReopenHistory > 2 OR rs.Reputation > 500)
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC, 
    p.CreationDate DESC;
