WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        RANK() OVER (ORDER BY p.Score DESC) AS RankByScore
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
      AND p.ViewCount IS NOT NULL
),

UserVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (3, 10) THEN 1 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),

PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS AllComments
    FROM Comments c
    GROUP BY c.PostId
),

PostsWithRanks AS (
    SELECT 
        p.*,
        rp.RankByViews,
        rp.RankByScore,
        uv.UpVotes,
        uv.DownVotes,
        pc.CommentCount,
        pc.AllComments
    FROM RankedPosts rp
    LEFT JOIN Posts p ON p.Id = rp.PostId
    LEFT JOIN UserVotes uv ON uv.PostId = p.Id
    LEFT JOIN PostComments pc ON pc.PostId = p.Id
    WHERE rp.RankByViews <= 5 AND rp.RankByScore <= 10
)

SELECT 
    p.PostId,
    p.Title,
    COALESCE(p.CreationDate, '1900-01-01') AS CreationDate,
    p.ViewCount,
    COALESCE(p.UpVotes, 0) AS UpVotes,
    COALESCE(p.DownVotes, 0) AS DownVotes,
    COALESCE(p.CommentCount, 0) AS CommentCount,
    COALESCE(ROUND(100.0 * p.UpVotes / NULLIF((p.UpVotes + p.DownVotes), 0), 2), 0) AS UpvotePercentage,
    TRIM(BOTH ';' FROM p.AllComments) AS CommentsList
FROM 
    PostsWithRanks p
WHERE 
    p.PostId IS NOT NULL
ORDER BY 
    p.RankByScore DESC, 
    p.RankByViews ASC
LIMIT 20
UNION ALL
SELECT 
    NULL AS PostId,
    'Summary of Posts' AS Title,
    NULL AS CreationDate,
    NULL AS ViewCount,
    NULL AS UpVotes,
    NULL AS DownVotes,
    SUM(COALESCE(CommentCount, 0)) AS CommentCount,
    NULL AS UpvotePercentage,
    NULL AS CommentsList
FROM 
    PostsWithRanks
HAVING COUNT(PostId) > 0
;
