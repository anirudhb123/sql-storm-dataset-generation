WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(v.VoteTypeId = 2) AS UpVotesReceived,
        SUM(v.VoteTypeId = 3) AS DownVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreateDate,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.FavoriteCount, 0) AS FavoriteCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT ParentId, COUNT(Id) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) a ON p.Id = a.ParentId
    LEFT JOIN 
        (SELECT PostId, COUNT(Id) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS FavoriteCount FROM Votes WHERE VoteTypeId = 5 GROUP BY PostId) b ON p.Id = b.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.UpVotesReceived,
    ua.DownVotesReceived,
    ps.Title,
    ps.ViewCount,
    ps.CreateDate,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount
FROM 
    UserActivity ua
JOIN 
    PostStatistics ps ON ua.UserId = ps.OwnerUserId
ORDER BY 
    ua.UpVotesReceived DESC, 
    ua.TotalPosts DESC;
