-- Performance benchmarking SQL query for StackOverflow schema
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT a.Id) AS TotalAnswers,
        SUM(COALESCE(v.Score, 0)) AS TotalScore,
        SUM(COALESCE(c.Score, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalAnswers,
    us.TotalScore,
    us.TotalComments,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount
FROM 
    UserStats us
JOIN 
    PostStats ps ON us.UserId = ps.PostId
ORDER BY 
    us.TotalScore DESC, us.TotalPosts DESC;
