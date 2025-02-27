-- Performance benchmarking query to analyze posts, comments, and user engagement.
WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(vote.VoteTypeId = 2), 0) AS UpvoteCount, -- Upvotes
        COALESCE(SUM(vote.VoteTypeId = 3), 0) AS DownvoteCount -- Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vote ON p.Id = vote.PostId
    GROUP BY 
        p.Id
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        SUM(u.UpVotes) AS TotalUpvotes,
        SUM(u.DownVotes) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CreationDate,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ue.UserId,
    ue.DisplayName,
    ue.PostsCount,
    ue.CommentsCount,
    ue.TotalUpvotes,
    ue.TotalDownvotes
FROM 
    PostSummary ps
JOIN 
    Users ue ON ps.UserId = ue.Id -- Assuming the original column for user is retained in the Posts table
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC
LIMIT 100; -- Adjust the limit as needed for benchmarking
