
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        @row_number := IF(@current_owner = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @current_owner := p.OwnerUserId
    FROM 
        Posts p, (SELECT @row_number := 0, @current_owner := NULL) r
    WHERE 
        p.Score IS NOT NULL AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL 2 YEAR
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
), 
UserBadges AS (
    SELECT 
        u.Id AS UserID,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(CONCAT(ph.Comment, ' (', pht.Name, ')') ORDER BY ph.CreationDate ASC SEPARATOR '; ') AS Comments,
        MAX(ph.CreationDate) AS LastUpdate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    p.PostID,
    p.Title,
    p.CreationDate,
    p.Score,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    ph.Comments,
    ph.LastUpdate
FROM 
    RankedPosts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserID
LEFT JOIN 
    PostHistoryInfo ph ON p.PostID = ph.PostId
WHERE 
    (p.PostRank = 1 OR p.Score >= 10) AND
    (u.Reputation IS NOT NULL AND u.Reputation > 100 OR u.AccountId IS NULL)
ORDER BY 
    p.Score DESC, 
    p.CreationDate ASC;
