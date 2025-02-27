WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as UserRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND 
        p.Score > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(b.Id) AS BadgeCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        c.Text AS CommentText,
        c.CreationDate AS CommentDate,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.ViewCount > 100
)
SELECT 
    u.DisplayName,
    up.UserRank,
    p.Title AS PostTitle,
    p.CreationDate AS PostDate,
    COALESCE(c.CommentText, 'No comments') AS LatestComment,
    COALESCE(c.CommentDate, p.CreationDate) AS LastActivity,
    us.TotalBounties,
    us.BadgeCount,
    us.AvgReputation
FROM 
    Users u
JOIN 
    RankedPosts up ON u.Id = up.OwnerUserId
JOIN 
    PostsWithComments p ON p.PostId = up.Id
JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    LATERAL (
        SELECT 
            c.Text,
            c.CreationDate
        FROM 
            Comments c
        WHERE 
            c.PostId = p.PostId
        ORDER BY 
            c.CreationDate DESC
        LIMIT 1
    ) AS c ON true
WHERE 
    up.UserRank <= 5
ORDER BY 
    us.AvgReputation DESC, 
    p.PostDate DESC
LIMIT 10;
