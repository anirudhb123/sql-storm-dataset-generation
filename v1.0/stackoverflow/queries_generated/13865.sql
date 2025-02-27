-- Performance Benchmarking Query
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month' -- Posts created in the last month
), 
PostStatistics AS (
    SELECT 
        PostId,
        COUNT(distinct c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes, -- Assuming VoteTypeId = 2 is upvote
        SUM(v.VoteTypeId = 3) AS DownVotes -- Assuming VoteTypeId = 3 is downvote
    FROM 
        RecentPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        PostId
)

SELECT 
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    rp.OwnerDisplayName
FROM 
    RecentPosts rp
JOIN 
    PostStatistics ps ON rp.PostId = ps.PostId
ORDER BY 
    rp.ViewCount DESC, -- Top viewed posts first
    rp.CreationDate DESC; -- Then by latest posts
