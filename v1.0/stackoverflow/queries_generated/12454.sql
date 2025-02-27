-- Performance benchmarking query to analyze posts and their related users and comments
WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
    GROUP BY
        p.Id, u.DisplayName, u.Reputation
)
SELECT
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    UpVotes,
    DownVotes,
    OwnerDisplayName,
    OwnerReputation
FROM
    PostStats
ORDER BY
    Score DESC
LIMIT 100;  -- Limit to top 100 posts by score for benchmarking
