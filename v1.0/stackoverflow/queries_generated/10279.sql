-- Performance Benchmarking Query to analyze Posts and their associated Users, Votes, and Comments
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= '2023-01-01'  -- Filtering for posts created in 2023
    GROUP BY 
        p.Id, u.Reputation
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.CreationDate,
    ps.OwnerReputation,
    ps.TotalComments,
    ps.TotalVotes,
    ps.TotalBadges
FROM 
    PostStats ps
ORDER BY 
    ps.ViewCount DESC, 
    ps.Score DESC
LIMIT 100;  -- Limiting to top 100 posts for better performance in benchmarking
