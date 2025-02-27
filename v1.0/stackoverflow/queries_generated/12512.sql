-- Performance benchmarking query to analyze post statistics and user engagement on the StackOverflow schema.

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS OwnerReputation,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(month, -6, GETDATE())  -- Focusing on posts from the last 6 months
    GROUP BY 
        p.Id, u.Reputation
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    ps.OwnerReputation,
    ps.VoteCount,
    ue.UserId,
    ue.DisplayName,
    ue.BadgeCount,
    ue.TotalViews,
    ue.TotalAnswers
FROM 
    PostStats ps
JOIN 
    UserEngagement ue ON ps.OwnerReputation = ue.UserId  -- Join to get user engagement metrics
ORDER BY 
    ps.CreatedDate DESC; -- Order by creation date to see the latest posts first
