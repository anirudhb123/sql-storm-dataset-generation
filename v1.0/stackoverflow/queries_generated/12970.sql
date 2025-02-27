-- Performance Benchmarking Query

WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        pt.Name AS PostType,
        COUNT(DISTINCT vh.Id) AS VoteCount
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes vh ON p.Id = vh.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, pt.Name
)
SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.PostCount,
    ue.TotalViews,
    ue.TotalScore,
    ue.CommentCount,
    ue.BadgeCount,
    pm.PostId,
    pm.Title AS PostTitle,
    pm.CreationDate AS PostCreationDate,
    pm.Score AS PostScore,
    pm.ViewCount AS PostViewCount,
    pm.AnswerCount AS PostAnswerCount,
    pm.CommentCount AS PostCommentCount,
    pm.PostType,
    pm.VoteCount
FROM 
    UserEngagement ue
LEFT JOIN 
    PostMetrics pm ON ue.UserId = pm.OwnerUserId
ORDER BY 
    ue.TotalScore DESC, 
    ue.TotalViews DESC;
