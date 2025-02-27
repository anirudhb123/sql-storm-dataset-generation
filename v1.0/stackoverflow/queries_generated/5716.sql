WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpvoteCount,
        SUM(v.VoteTypeId = 3) AS DownvoteCount,
        MAX(p.CreationDate) AS LastActivity,
        COALESCE(MAX(b.Date), '1970-01-01') AS LastBadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title, pt.Name
),
CombinedStats AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostsCreated,
        ua.CommentsMade,
        ua.UpvotesReceived,
        ua.DownvotesReceived,
        ps.PostId,
        ps.Title,
        ps.PostType,
        ps.CommentCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        ps.LastActivity,
        ps.LastBadgeDate
    FROM 
        UserActivity ua
    JOIN 
        PostStats ps ON ua.UserId = p.OwnerUserId
)

SELECT 
    UserId,
    DisplayName,
    PostsCreated,
    CommentsMade,
    UpvotesReceived,
    DownvotesReceived,
    COUNT(PostId) AS TotalPosts,
    SUM(CommentCount) AS TotalCommentsOnPosts,
    SUM(UpvoteCount) AS TotalUpvotesReceived,
    SUM(DownvoteCount) AS TotalDownvotesReceived,
    MAX(LastActivity) AS MostRecentActivity,
    MAX(LastBadgeDate) AS LastBadgeAwarded
FROM 
    CombinedStats
GROUP BY 
    UserId, DisplayName, PostsCreated, CommentsMade, UpvotesReceived, DownvotesReceived
ORDER BY 
    TotalPosts DESC, UpvotesReceived DESC
LIMIT 100;
