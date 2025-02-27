WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rb.BadgeCount,
    pha.EditCount,
    pha.LastEditDate
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserBadges rb ON u.Id = rb.UserId
JOIN 
    PostHistoryAggregates pha ON rp.PostId = pha.PostId
WHERE 
    rp.RankScore <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
