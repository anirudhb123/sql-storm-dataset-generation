WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
RecentBadges AS (
    SELECT 
        b.UserId, 
        b.Name AS BadgeName,
        ROW_NUMBER() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Badges b
    WHERE 
        b.Date > NOW() - INTERVAL '1 YEAR'
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) -- Edits to Title or Body
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankScore,
        COALESCE(pb.EditCount, 0) AS EditCount,
        COALESCE(b.LastEditDate, '1970-01-01') AS LastEditDate, -- Placeholder for NULL
        COALESCE(rb.UserId, -1) AS UserWithRecentBadge, -- Using -1 for NULL logic
        COALESCE(rb.BadgeName, 'No Badge') AS RecentBadgeName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistories pb ON rp.PostId = pb.PostId
    LEFT JOIN 
        RecentBadges rb ON rp.PostId = rb.UserId AND rb.BadgeRank = 1
    WHERE 
        rp.RankScore <= 10 AND -- Top 10 based on score
        rp.ViewCount > 1000 -- Popular Posts Only
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    fr.EditCount,
    fr.LastEditDate,
    fr.UserWithRecentBadge,
    fr.RecentBadgeName
FROM 
    FinalResults fr
WHERE 
    fr.UserWithRecentBadge IS NOT NULL -- Users with badges
ORDER BY 
    fr.Score DESC, fr.EditCount DESC; 
