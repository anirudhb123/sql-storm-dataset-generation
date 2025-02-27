WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(b.Class) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.UpvotedPosts,
    ua.DownvotedPosts,
    ua.TotalBounties,
    ua.TotalBadges,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Upvotes,
    ps.Downvotes,
    ps.CommentCount,
    ps.ClosedCount,
    ps.ReopenedCount
FROM 
    UserActivity ua
JOIN 
    PostStatistics ps ON ua.UserId = ps.PostId
WHERE 
    ua.PostCount > 0 
ORDER BY 
    ua.TotalBadges DESC, 
    ps.Upvotes DESC
LIMIT 100;
