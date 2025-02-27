
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        @row_number := IF(@prev_user_id = p.OwnerUserId, @row_number + 1, 1) AS UserRank,
        @prev_user_id := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id,
        (SELECT @row_number := 0, @prev_user_id := NULL) AS vars
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR 
        AND p.ViewCount > 10
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name ORDER BY b.Date SEPARATOR ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    pha.FirstEditDate,
    pha.LastEditDate,
    pha.EditCount,
    ub.UserId AS BadgeUserId,
    ub.BadgeCount,
    ub.BadgeNames
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAggregated pha ON pha.PostId = rp.Id
LEFT JOIN 
    UserBadges ub ON ub.UserId = rp.OwnerUserId
WHERE 
    (rp.UserRank = 1 OR rp.UserRank IS NULL)
    AND (ub.BadgeCount IS NOT NULL AND ub.BadgeCount >= 3)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
