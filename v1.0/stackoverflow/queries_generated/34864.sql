WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(c.Id) DESC, p.CreationDate ASC) AS Rank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId 
    WHERE p.CreationDate >= NOW() - INTERVAL '1 YEAR' -- Posts created in the last year
    GROUP BY p.Id, p.Title, p.Tags
),
MostCommentedPosts AS (
    SELECT
        PostId,
        Title,
        Tags,
        CommentCount,
        UpVotes,
        DownVotes
    FROM RankedPosts
    WHERE Rank <= 10
),
RecentVotes AS (
    SELECT
        PostId,
        COUNT(*) AS VoteCount
    FROM Votes
    WHERE CreationDate >= NOW() - INTERVAL '1 MONTH'
    GROUP BY PostId
)
SELECT
    mcp.PostId,
    mcp.Title,
    mcp.Tags,
    mcp.CommentCount,
    mcp.UpVotes,
    mcp.DownVotes,
    COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
    CASE 
        WHEN mcp.UpVotes = 0 THEN 0
        ELSE (mcp.UpVotes * 1.0 / (mcp.UpVotes + mcp.DownVotes)) * 100
    END AS UpvotePercentage,
    CASE 
        WHEN mcp.UpVotes IS NULL THEN 'No votes yet'
        ELSE 'Votes exist'
    END AS VoteStatus
FROM MostCommentedPosts mcp
LEFT JOIN RecentVotes rv ON mcp.PostId = rv.PostId
ORDER BY mcp.CommentCount DESC, mcp.UpVotes DESC;

