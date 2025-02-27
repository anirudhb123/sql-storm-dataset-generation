WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.Score IS NOT NULL
),
ClosedPostStats AS (
    SELECT 
        p.Id,
        ph.UserId AS ClosedByUserId,
        MAX(ph.CreationDate) AS ClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    WHERE 
        p.ClosedDate IS NOT NULL
    GROUP BY 
        p.Id, ph.UserId
)
SELECT 
    ua.DisplayName,
    ua.PositivePosts,
    ua.NegativePosts,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBounty,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    cp.ClosedDate,
    COALESCE(NULLIF(ps.RecentPostRank, 0), 'No Recent Posts') AS RecentPostStats
FROM 
    UserActivity ua
LEFT JOIN 
    PostStats ps ON ua.UserId = ps.OwnerDisplayName
LEFT JOIN 
    ClosedPostStats cp ON ps.PostId = cp.Id
WHERE 
    ua.TotalPosts > 5
ORDER BY 
    ua.TotalBounty DESC,
    ua.PositivePosts DESC;
