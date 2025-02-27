WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),

TopScoredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 5
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Name AS BadgeName,
        b.Class,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, b.Name, b.Class
)

SELECT 
    p.Title,
    p.Score,
    p.ViewCount,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    STRING_AGG(DISTINCT ub.BadgeName, ', ') AS BadgeNames
FROM 
    TopScoredPosts p
LEFT JOIN 
    UserBadges b ON b.UserId = p.OwnerUserId
LEFT JOIN 
    UserBadges ub ON ub.UserId = p.OwnerUserId AND ub.Class = 1
GROUP BY 
    p.Id, p.Title, p.Score, p.ViewCount
ORDER BY 
    p.Score DESC, BadgeCount DESC
LIMIT 10;

WITH PostsWithCloseReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        ph.CreationDate,
        ph.UserDisplayName
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Considering Close and Reopen events
),

CloseDetails AS (
    SELECT 
        p.Id AS PostId,
        COUNT(pcr.Comment) AS CloseReasonCount,
        MAX(pcr.CreationDate) AS LastCloseDate
    FROM 
        Posts p
    LEFT JOIN 
        PostsWithCloseReasons pcr ON pcr.PostId = p.Id
    GROUP BY 
        p.Id
)

SELECT 
    p.Title,
    cd.CloseReasonCount,
    cd.LastCloseDate
FROM 
    Posts p
JOIN 
    CloseDetails cd ON cd.PostId = p.Id
WHERE 
    cd.CloseReasonCount > 0
ORDER BY 
    cd.LastCloseDate DESC;
