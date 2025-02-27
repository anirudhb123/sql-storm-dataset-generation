WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(COALESCE(vs.VoteCount, 0)) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) vs ON p.Id = vs.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(COMMENT_STATS.CommentCount, 0) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) COMMENT_STATS ON p.Id = COMMENT_STATS.PostId
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.TotalVotes,
    ps.Title AS TopPostTitle,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount
FROM 
    UserActivity ua
LEFT JOIN 
    PostStats ps ON ua.TotalPosts > 0
WHERE 
    ua.TotalVotes > (
        SELECT 
            AVG(TotalVotes)
        FROM 
            UserActivity
    ) 
    AND ua.TotalPosts > 5
ORDER BY 
    ua.TotalVotes DESC, 
    ua.TotalPosts DESC;
