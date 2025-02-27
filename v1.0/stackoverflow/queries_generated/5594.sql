WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        SUM(b.Class) AS BadgeScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.CreationDate
),
UserPostDetails AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        COUNT(ps.PostId) AS TotalPosts,
        COUNT(DISTINCT ps.PostId) AS ActivePosts,
        AVG(EXTRACT(EPOCH FROM (ps.LastEditDate - ps.CreationDate))/3600) AS AvgEditDuration
    FROM 
        UserActivity ua
    LEFT JOIN 
        PostStatistics ps ON ua.UserId = ps.OwnerUserId
    GROUP BY 
        ua.UserId, ua.DisplayName
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalPosts,
    up.ActivePosts,
    up.AvgEditDuration,
    ua.PostCount,
    ua.CommentCount,
    ua.UpvoteCount,
    ua.DownvoteCount,
    ua.BadgeScore
FROM 
    UserPostDetails up
JOIN 
    UserActivity ua ON up.UserId = ua.UserId
WHERE 
    up.ActivePosts > 0 
ORDER BY 
    up.AvgEditDuration DESC, ua.BadgeScore DESC;
