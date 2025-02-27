WITH UserVotes AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(b.Class) AS BadgeClassSum -- Aggregating badge classes of post owners
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year' -- Filtering posts created in the last year
    GROUP BY p.Id, u.DisplayName
),
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerDisplayName,
        pd.Score,
        pd.ViewCount,
        pd.CommentCount,
        RANK() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS RankScore
    FROM PostDetails pd
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    uv.UserId,
    uv.VoteCount,
    uv.UpVotes,
    uv.DownVotes
FROM RankedPosts rp
LEFT JOIN UserVotes uv ON uv.UserId IN (
    SELECT UserId 
    FROM Votes v 
    WHERE v.PostId = rp.PostId
)
WHERE rp.RankScore <= 50 -- Limiting to top 50 ranked posts
ORDER BY rp.Score DESC, rp.ViewCount DESC;
