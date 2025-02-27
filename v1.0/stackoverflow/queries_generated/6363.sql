WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        BadgeCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    t.OwnerDisplayName,
    COUNT(DISTINCT t.PostId) AS TotalPosts,
    AVG(t.Score) AS AverageScore,
    SUM(t.ViewCount) AS TotalViews,
    SUM(t.CommentCount) AS TotalComments,
    SUM(t.BadgeCount) AS TotalBadges
FROM 
    TopPosts t
JOIN 
    Users u ON t.OwnerDisplayName = u.DisplayName
GROUP BY 
    t.OwnerDisplayName
ORDER BY 
    TotalPosts DESC, AverageScore DESC
LIMIT 10;
