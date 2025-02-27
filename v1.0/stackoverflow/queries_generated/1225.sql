WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        COALESCE(pg.AvgScore, 0) AS AvgScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId IN (2, 3)) AS UpDownVoteCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN (
            SELECT 
                PostId, 
                AVG(Score) AS AvgScore 
            FROM 
                Posts 
            GROUP BY 
                PostId
        ) pg ON p.Id = pg.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, pg.AvgScore
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Posts that were closed
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.CreationDate,
    pd.Score,
    pd.AvgScore,
    pd.CommentCount,
    pd.UpDownVoteCount,
    pd.Rank,
    COALESCE(cp.ClosedDate, 'Not Closed') AS ClosedDate,
    COALESCE(cp.ClosedBy, 'Active') AS ClosedBy
FROM 
    PostDetails pd
LEFT JOIN 
    ClosedPosts cp ON pd.PostId = cp.ClosedPostId
WHERE 
    pd.CommentCount > 5
ORDER BY 
    pd.Rank,
    pd.Score DESC
LIMIT 100;
