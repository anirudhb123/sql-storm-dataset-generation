-- Performance benchmarking query to analyze user activity and post metrics

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 0 -- Considering only users with positive reputation
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.CommentCount,
        p.AnswerCount,
        p.FavoriteCount,
        p.ClosedDate,
        PT.Name AS PostType
    FROM 
        Posts p
    JOIN 
        PostTypes PT ON p.PostTypeId = PT.Id
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalViews,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.LastPostDate,
    pm.PostId,
    pm.Title,
    pm.CreationDate AS PostCreationDate,
    pm.Score,
    pm.CommentCount,
    pm.AnswerCount,
    pm.FavoriteCount,
    pm.ClosedDate,
    pm.PostType
FROM 
    UserStats us
LEFT JOIN 
    PostMetrics pm ON us.TotalPosts > 0
ORDER BY 
    us.TotalPosts DESC, us.LastPostDate DESC
LIMIT 100; -- Limit to top 100 users
