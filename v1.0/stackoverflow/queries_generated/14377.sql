-- Performance Benchmarking Query

WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalBadges,
    us.TotalUpvotes,
    us.TotalDownvotes,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.ViewCount,
    ps.Score AS PostScore,
    ps.CreationDate AS PostCreationDate,
    ps.TotalComments,
    ps.TotalVotes
FROM 
    UserStatistics us
JOIN 
    PostStatistics ps ON us.UserId = ps.OwnerUserId
ORDER BY 
    us.TotalPosts DESC, us.TotalUpvotes DESC;
