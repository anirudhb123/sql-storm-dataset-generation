WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankByScore,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.Deleted IS NULL
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankByScore,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.RankByScore <= 5 THEN 'Top' 
            ELSE 'Other' 
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Score > 10 OR rp.UpVotes - rp.DownVotes > 5
),
PostCommentCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.UpVotes,
    fp.DownVotes,
    pcc.CommentCount,
    CASE 
        WHEN pcc.CommentCount IS NULL THEN 'No Comments'
        ELSE 'Has Comments' 
    END AS CommentStatus,
    CONCAT('Score: ', CAST(fp.Score AS VARCHAR), ', Views: ', CAST(fp.ViewCount AS VARCHAR)) AS DisplayMetrics,
    CASE 
        WHEN fp.Score = (SELECT MAX(Score) FROM FilteredPosts) THEN 'Highest Score' 
        ELSE 'Regular Score' 
    END AS ScoreStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostCommentCounts pcc ON fp.PostId = pcc.PostId
WHERE 
    fp.PostCategory = 'Top'
ORDER BY 
    fp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
