
WITH RECURSIVE RecursiveTopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation,
        u.CreationDate,
        @row_number := @row_number + 1 AS Rank
    FROM 
        Users u, (SELECT @row_number := 0) r
    WHERE 
        u.Reputation > 1000
    ORDER BY 
        u.Reputation DESC
),
PostsRanked AS (
    SELECT 
        p.Id AS PostId, 
        p.OwnerUserId,
        p.Title, 
        p.CreationDate, 
        p.Score,
        COUNT(c.Id) AS CommentCount,
        @post_rank := IF(@current_user = p.OwnerUserId, @post_rank + 1, 1) AS PostRank,
        @current_user := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS JOIN (SELECT @post_rank := 0, @current_user := NULL) r
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.Score
), 
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.PostId) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        PostsRanked p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.PostId = c.PostId
    WHERE 
        u.Reputation > 500
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.Reputation,
    ups.TotalPosts,
    ups.TotalScore,
    ups.TotalComments
FROM 
    RecursiveTopUsers t
JOIN 
    UserPostStats ups ON t.UserId = ups.UserId
WHERE 
    ups.TotalPosts > 5
ORDER BY 
    t.Rank, ups.TotalScore DESC
LIMIT 10;
