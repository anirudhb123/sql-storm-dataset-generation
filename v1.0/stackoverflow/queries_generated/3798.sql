WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        u.DisplayName,
        b.Name AS BadgeName,
        COALESCE(SUM(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold badges
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    WHERE 
        rp.Rank <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.Rank, u.DisplayName, b.Name
)
SELECT 
    tp.*,
    CASE 
        WHEN tp.CommentCount > 5 THEN 'Hot'
        ELSE 'Normal'
    END AS PostStatus,
    CASE 
        WHEN tp.Score IS NOT NULL THEN ROUND(tp.Score::numeric / NULLIF(tp.ViewCount, 0), 2)
        ELSE NULL
    END AS ScoreToViewRatio
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC
UNION ALL
SELECT 
    NULL AS PostId,
    'Total Votes' AS Title,
    NULL AS Score,
    NULL AS ViewCount,
    NULL AS Rank,
    NULL AS DisplayName,
    NULL AS BadgeName,
    COUNT(*) AS CommentCount
FROM 
    Comments
WHERE 
    CreationDate >= NOW() - INTERVAL '1 month'
HAVING 
    COUNT(*) > 10;
