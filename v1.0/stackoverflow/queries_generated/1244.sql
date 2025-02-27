WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
RankedPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Score > 100 THEN 'High'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        RecentPosts rp
)
SELECT 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(rp.TotalBounty, 0) AS TotalBounty,
    rp.ScoreCategory
FROM 
    RankedPosts rp
WHERE 
    rp.rn = 1 
    AND rp.CommentCount > 5
ORDER BY 
    COALESCE(rp.TotalBounty, 0) DESC, rp.CreationDate DESC;

-- Additional benchmark performance queries
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AverageViews
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
GROUP BY 
    pt.Name;

SELECT 
    ut.Name AS UserType,
    COUNT(u.Id) AS UserCount,
    SUM(u.Reputation) AS TotalReputation
FROM 
    Users u
LEFT JOIN 
    Users u2 ON u.Id = u2.Id -- Using outer join for completeness; allows for user types without posts
LEFT JOIN 
    (SELECT id, CASE WHEN Reputation > 1000 THEN 'Experienced' ELSE 'Novice' END AS Name 
    FROM Users) ut ON u.Id = ut.Id
GROUP BY 
    ut.Name
ORDER BY 
    UserCount DESC;
