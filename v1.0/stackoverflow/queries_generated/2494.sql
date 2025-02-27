WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR' 
        AND p.Score > 0
    GROUP BY 
        p.Id, U.DisplayName
),
RecentBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= NOW() - INTERVAL '1 MONTH'
    GROUP BY 
        b.UserId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    COALESCE(rb.BadgeNames, 'No Badges') AS RecentBadges,
    CASE 
        WHEN rp.ViewCount > 100 THEN 'High Traffic'
        WHEN rp.ViewCount BETWEEN 50 AND 100 THEN 'Moderate Traffic'
        ELSE 'Low Traffic'
    END AS TrafficCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentBadges rb ON rp.OwnerUserId = rb.UserId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 10;

WITH Recursive LinkChain AS (
    SELECT 
        pl.PostId, 
        pl.RelatedPostId, 
        1 AS Depth
    FROM 
        PostLinks pl
    WHERE 
        pl.PostId IN (SELECT Id FROM Posts WHERE Score > 10)
    
    UNION ALL
    
    SELECT 
        pl.PostId, 
        pl.RelatedPostId, 
        lc.Depth + 1
    FROM 
        PostLinks pl
    JOIN 
        LinkChain lc ON pl.PostId = lc.RelatedPostId
    WHERE 
        lc.Depth < 3
)
SELECT 
    pc.PostId,
    COUNT(DISTINCT lc.RelatedPostId) AS LinkCount,
    SUM(CASE 
        WHEN lc.Depth = 1 THEN 1 
        ELSE 0 
    END) AS DirectLinks,
    SUM(CASE 
        WHEN lc.Depth = 2 THEN 1 
        ELSE 0 
    END) AS IndirectLinks
FROM 
    Posts pc
LEFT JOIN 
    LinkChain lc ON pc.Id = lc.PostId
GROUP BY 
    pc.Id
ORDER BY 
    LinkCount DESC
LIMIT 5;
