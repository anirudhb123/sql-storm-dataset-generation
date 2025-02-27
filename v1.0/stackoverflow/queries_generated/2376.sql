WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score, p.OwnerUserId
)

SELECT 
    u.DisplayName,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.RankScore,
    COALESCE(b.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN rp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus,
    CASE 
        WHEN rp.TotalUpvotes > 0 THEN 'Upvoted'
        ELSE 'Not Upvoted'
    END AS VoteStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON u.Id = rp.OwnerUserId
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges 
    GROUP BY 
        UserId
) b ON b.UserId = u.Id
WHERE 
    rp.RankScore <= 5
UNION ALL
SELECT 
    'Total',
    NULL,
    SUM(ViewCount),
    SUM(Score),
    NULL,
    NULL,
    NULL,
    NULL
FROM 
    RankedPosts
HAVING 
    COUNT(*) > 0
ORDER BY 
    Score DESC, ViewCount DESC;
