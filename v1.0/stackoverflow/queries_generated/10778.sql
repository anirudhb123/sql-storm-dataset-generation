-- Performance benchmarking query to analyze user activity and post engagement
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(c.Id IS NOT NULL) AS TotalComments,
        SUM(v.Id IS NOT NULL) AS TotalVotes,
        SUM(b.Id IS NOT NULL) AS TotalBadges,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    ua.TotalComments,
    ua.TotalVotes,
    ua.TotalBadges,
    ua.TotalViews,
    pe.PostId,
    pe.Title,
    pe.CreationDate,
    pe.ViewCount,
    pe.AnswerCount,
    pe.CommentCount,
    pe.UpVotes,
    pe.DownVotes
FROM 
    UserActivity ua
JOIN 
    PostEngagement pe ON ua.UserId = pe.PostId -- Joining both CTEs on PostId for engagement metrics
ORDER BY 
    ua.TotalPosts DESC, pe.ViewCount DESC; -- Order by total posts and post views
