-- Performance benchmarking query to analyze posts and their associated votes and comments
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        IFNULL(SUM(v.VoteTypeId = 2), 0) AS UpVotes,   -- Count Upvotes
        IFNULL(SUM(v.VoteTypeId = 3), 0) AS DownVotes  -- Count Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' -- Consider posts created in 2023
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
), 
PostVoteSummary AS (
    SELECT 
        PostId, 
        SUM(UpVotes - DownVotes) AS NetVotes -- Calculate net votes for each post
    FROM 
        PostStats
    GROUP BY 
        PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.CommentCount,
    pvs.NetVotes
FROM 
    PostStats ps
JOIN 
    PostVoteSummary pvs ON ps.PostId = pvs.PostId
ORDER BY 
    ps.CreationDate DESC; -- Order by creation date, most recent first
