-- Performance benchmarking query to analyze post and user engagements on Stack Overflow

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.Reputation AS OwnerReputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, u.Reputation
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(ps.ViewCount) AS TotalViews,
        SUM(ps.Score) AS TotalScore,
        SUM(ps.AnswerCount) AS TotalAnswers,
        SUM(ps.CommentCount) AS TotalComments
    FROM 
        Users u
    JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    p.Title,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ue.DisplayName AS PostOwner,
    ue.TotalViews AS OwnerTotalViews,
    ue.TotalScore AS OwnerTotalScore
FROM 
    PostStats ps
JOIN 
    UserEngagement ue ON ps.OwnerUserId = ue.UserId
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC
LIMIT 100;
