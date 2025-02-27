-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves various aggregates regarding posts, users, and their interactions.

WITH PostAggregates AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId
),
UserAggregates AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViewCount,
        SUM(CASE WHEN p.OwnerUserId = u.Id THEN 1 ELSE 0 END) AS PostsCreated
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT 
    pa.PostId,
    pa.PostTypeId,
    pa.CommentCount,
    pa.UniqueVoteCount,
    pa.Upvotes,
    pa.Downvotes,
    ua.UserId,
    ua.BadgeCount,
    ua.TotalViewCount,
    ua.PostsCreated
FROM 
    PostAggregates pa
JOIN 
    Users u ON pa.PostTypeId IN (1, 2) -- Assuming we want to filter for Questions and Answers only
JOIN 
    UserAggregates ua ON u.Id = pa.OwnerUserId
ORDER BY 
    pa.CommentCount DESC, pa.Upvotes DESC;
