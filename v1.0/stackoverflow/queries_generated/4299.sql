WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentTotal
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        RANK() OVER (ORDER BY SUM(p.ViewCount) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5
)
SELECT 
    tu.DisplayName,
    tu.TotalViews,
    rp.Title,
    rp.ViewCount,
    rp.CommentTotal,
    CASE 
        WHEN rp.Rank <= 3 THEN 'Top Post'
        ELSE 'Other Post'
    END AS PostCategory
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.PostId
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.TotalViews DESC, rp.ViewCount DESC
LIMIT 100;

-- Add an outer join to include users without posts
SELECT 
    COALESCE(tu.DisplayName, 'No posts') AS UserName,
    COALESCE(tu.TotalViews, 0) AS TotalViews,
    rp.Title,
    rp.ViewCount,
    rp.CommentTotal
FROM 
    TopUsers tu
FULL OUTER JOIN 
    RankedPosts rp ON tu.UserId = rp.PostId
ORDER BY 
    TotalViews DESC
LIMIT 50;

-- Including a correlated subquery to get the max view count for posts by each user
SELECT 
    u.DisplayName,
    (SELECT MAX(p.ViewCount) FROM Posts p WHERE p.OwnerUserId = u.Id) AS MaxViewCount
FROM 
    Users u
WHERE 
    u.Reputation > (
        SELECT AVG(Reputation) FROM Users
    )
ORDER BY 
    MaxViewCount DESC
LIMIT 10;
