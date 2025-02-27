-- Performance benchmarking query for Stack Overflow schema

WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,  -- Count of Upvotes
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount   -- Count of Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpvoteCount,  -- Total Upvotes for the post
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownvoteCount  -- Total Downvotes for the post
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    up.UpvoteCount,
    down.DownvoteCount,
    p.Title AS PostTitle,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.UpvoteCount AS PostUpvoteCount,
    p.DownvoteCount AS PostDownvoteCount
FROM 
    Users u
JOIN 
    UserVoteCounts up ON u.Id = up.UserId
JOIN 
    UserVoteCounts down ON u.Id = down.UserId
JOIN 
    Posts p ON u.Id = p.OwnerUserId
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit results to the latest 100 posts for benchmarking
