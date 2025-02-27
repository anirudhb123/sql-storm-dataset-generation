WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) DESC) AS UserRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Class,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class IN (1, 2, 3) -- Gold, Silver, Bronze
    GROUP BY 
        u.Id, b.Class
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryCreationDate,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10) -- Title edited, Body edited, Post closed
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UserRank,
        ub.BadgeCount,
        CASE
            WHEN rph.HistoryCreationDate IS NOT NULL THEN 
                EXTRACT(EPOCH FROM (NOW() - rph.HistoryCreationDate)) / 3600 -- Hours since last edit
            ELSE NULL
        END AS HoursSinceLastEdit
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        RecentPostHistory rph ON rp.PostId = rph.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.UserRank,
    ps.BadgeCount,
    ps.HoursSinceLastEdit,
    CASE 
        WHEN ps.HoursSinceLastEdit < 24 THEN 'Recently Edited'
        WHEN ps.HoursSinceLastEdit IS NULL THEN 'Never Edited'
        ELSE 'Edited Long Ago'
    END AS EditStatus
FROM 
    PostStatistics ps
WHERE 
    ps.Score > 0 -- Only include posts with positive scores
ORDER BY 
    ps.Score DESC, ps.UserRank ASC;
