-- Performance Benchmarking Query
-- This query retrieves statistics related to posts, users, and comments to evaluate query execution times.

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(vt.VoteTypeId = 2) AS UpVoteCount,
        SUM(vt.VoteTypeId = 3) AS DownVoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= '2022-01-01' -- Filter for posts created in 2022
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(vt.VoteTypeId = 2) AS TotalUpVotes,
        SUM(vt.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.PostTypeId,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.TotalUpVotes,
    us.TotalDownVotes
FROM 
    PostStats ps
JOIN 
    Users us ON ps.UserId = us.UserId
ORDER BY 
    ps.CommentCount DESC, ps.UpVoteCount DESC
LIMIT 100; -- Limiting result for performance testing
