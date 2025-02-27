WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(b.Id) AS BadgeCount,
        AVG(b.Class) AS AverageBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.TotalBounty,
    u.DisplayName,
    u.TotalViews,
    u.BadgeCount,
    u.AverageBadgeClass,
    CASE 
        WHEN r.RankScore = 1 THEN 'Top Post'
        WHEN r.RankScore <= 5 THEN 'Top 5 Post'
        ELSE 'Other Post'
    END AS PostCategory
FROM 
    RankedPosts r
JOIN 
    UserStats u ON r.OwnerUserId = u.UserId
WHERE 
    u.TotalViews > 100 
    AND r.CommentCount > 10
ORDER BY 
    r.Score DESC, 
    r.ViewCount DESC
LIMIT 50;

