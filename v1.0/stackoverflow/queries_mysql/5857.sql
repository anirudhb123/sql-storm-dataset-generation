
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        @row_number := IF(@prev_name = pt.Name, @row_number + 1, 1) AS Rank,
        @prev_name := pt.Name,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS JOIN 
        (SELECT @row_number := 0, @prev_name := '') AS rn
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, pt.Name
),
TopRankedPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.Rank <= 5
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    t.PostId,
    t.Title,
    t.OwnerDisplayName,
    t.CreationDate,
    t.Score,
    t.ViewCount,
    u.DisplayName AS UserName,
    u.TotalBounty,
    u.BadgeCount,
    u.TotalViews
FROM 
    TopRankedPosts t
JOIN 
    UserStats u ON t.OwnerDisplayName = u.DisplayName
ORDER BY 
    t.Score DESC, t.ViewCount DESC;
