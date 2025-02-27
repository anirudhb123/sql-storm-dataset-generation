-- Performance Benchmarking Query

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,  -- Count Upvotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,  -- Count Downvotes
        COUNT(c.Id) AS CommentCount,                       -- Count Comments
        COUNT(DISTINCT ph.Id) AS RevisionCount             -- Count Revisions
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.PostTypeId
),

TopPosts AS (
    SELECT 
        ps.PostId,
        ps.PostTypeId,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        ps.RevisionCount,
        ROW_NUMBER() OVER (ORDER BY ps.UpVotes DESC, ps.CommentCount DESC) AS Rank
    FROM 
        PostStats ps
    WHERE 
        ps.PostTypeId IN (1, 2)  -- Only Questions (1) and Answers (2)
)

SELECT 
    tp.PostId,
    tp.PostTypeId,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    tp.RevisionCount
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10;  -- Get top 10 posts based on UpVotes and CommentCount
