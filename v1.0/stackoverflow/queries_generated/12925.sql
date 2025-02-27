-- Performance Benchmarking SQL Query for Stack Overflow Schema

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(b.Class) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalComments,
    us.TotalBounties,
    us.TotalBadges,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    ps.LastEditDate
FROM 
    UserStats us
LEFT JOIN 
    PostStats ps ON us.UserId = ps.PostId
ORDER BY 
    us.TotalPosts DESC, us.TotalComments DESC, us.TotalBounties DESC;
