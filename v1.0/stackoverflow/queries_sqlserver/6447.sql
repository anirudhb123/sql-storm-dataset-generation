
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56') AND 
        p.PostTypeId IN (1, 2) 
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(ISNULL(b.Class, 0)) AS TotalBadgeCount,
        SUM(ISNULL(v.BountyAmount, 0)) AS TotalBountySpent
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.LastAccessDate >= DATEADD(MONTH, -6, '2024-10-01 12:34:56')
    GROUP BY 
        u.Id, u.DisplayName
),
UserPostStats AS (
    SELECT 
        au.UserId,
        au.DisplayName,
        COUNT(rp.PostId) AS PostsCreated,
        SUM(rp.Score) AS TotalPostScore,
        SUM(rp.ViewCount) AS TotalViews
    FROM 
        ActiveUsers au
    LEFT JOIN 
        RankedPosts rp ON au.UserId = rp.OwnerUserId
    GROUP BY 
        au.UserId, au.DisplayName
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostsCreated,
    ups.TotalPostScore,
    ups.TotalViews,
    au.TotalBadgeCount,
    au.TotalBountySpent
FROM 
    UserPostStats ups
JOIN 
    ActiveUsers au ON ups.UserId = au.UserId
ORDER BY 
    ups.TotalPostScore DESC, ups.TotalViews DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
