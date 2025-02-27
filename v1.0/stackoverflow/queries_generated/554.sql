WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC) AS PostRank,
        MAX(v.VoteTypeId) AS MaxVoteType
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' AND 
        p.Score > 5
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.MaxVoteType = 2 THEN 'Upvoted'
            WHEN rp.MaxVoteType = 3 THEN 'Downvoted'
            ELSE 'No Votes'
        END AS VoteStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 0
)
SELECT 
    fp.Id,
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.CommentCount,
    fp.PostRank,
    fp.VoteStatus,
    COALESCE(e.DisplayName, 'Anonymous') AS LastEditor
FROM 
    FilteredPosts fp
LEFT JOIN 
    Users e ON fp.Id = e.Id
WHERE 
   	fp.PostRank <= 10
ORDER BY 
    fp.Score DESC
UNION ALL
SELECT 
    -1 AS Id,
    'Total Posts' AS Title,
    SUM(fp.ViewCount) AS ViewCount,
    SUM(fp.Score) AS TotalScore,
    SUM(fp.CommentCount) AS TotalComments,
    NULL AS PostRank,
    NULL AS VoteStatus,
    NULL AS LastEditor
FROM 
    FilteredPosts fp

