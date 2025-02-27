WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalPostViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AverageCommentScore
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.PostTypeId,
    ru.DisplayName AS UserDisplayName,
    ru.BadgeCount,
    ru.TotalPostViews,
    pc.CommentCount,
    pc.AverageCommentScore
FROM 
    RankedPosts rp
JOIN 
    Users u ON u.Id = rp.OwnerUserId
JOIN 
    RecentUsers ru ON u.Id = ru.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.PostTypeId, rp.Score DESC;
