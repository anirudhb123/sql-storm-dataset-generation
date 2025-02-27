WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Ranking,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v 
        ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
)
, BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b 
        ON u.Id = b.UserId
    WHERE 
        b.Date >= (CURRENT_DATE - INTERVAL '2 years') 
    GROUP BY 
        u.Id
)
, RecentActivity AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        p.OwnerUserId,
        ph.PostHistoryTypeId,
        COUNT(DISTINCT ph.UserId) AS EditorCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p 
        ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= (CURRENT_DATE - INTERVAL '30 days')
    GROUP BY 
        ph.PostId, ph.CreationDate, p.OwnerUserId, ph.PostHistoryTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.Ranking,
    bu.BadgeCount,
    bu.HighestBadgeClass,
    ra.EditorCount,
    COALESCE(ra.EditorCount, 0) AS EditorCountFallback, 
    CASE 
        WHEN bu.HighestBadgeClass IS NULL THEN 'No Badges' 
        ELSE CASE 
            WHEN bu.HighestBadgeClass = 1 THEN 'Gold'
            WHEN bu.HighestBadgeClass = 2 THEN 'Silver'
            ELSE 'Bronze'
        END
    END AS BadgeClass,
    (SELECT 
         COUNT(*) 
     FROM 
         Comments c 
     WHERE 
         c.PostId = rp.PostId 
         AND c.CreationDate >= (CURRENT_DATE - INTERVAL '1 month')) AS RecentCommentCount
FROM 
    RankedPosts rp
LEFT JOIN 
    BadgedUsers bu ON rp.OwnerUserId = bu.UserId
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
WHERE 
    (rp.UpVotes - rp.DownVotes) > 5
    OR (rp.Ranking <= 3 AND ra.EditorCount IS NOT NULL)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC, bu.BadgeCount DESC
LIMIT 50
OFFSET 10;

This SQL query showcases multiple advanced features such as Common Table Expressions (CTEs) to segment data, window functions for ranking posts and counting votes, correlated subqueries for comment counts, and conditional logic for badge classification. It integrates outer joins and utilizes complex filtering criteria, making it suitable for performance benchmarking.
