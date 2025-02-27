WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.UpvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 AND 
        rp.CommentCount > 5 AND 
        rp.UpvoteCount > 10
)
SELECT 
    fp.Title,
    fp.ViewCount,
    fp.Score,
    COALESCE(um.Reputation, 0) AS UserReputation,
    COALESCE(post_history.Comment, 'No Comments') AS LastPostAction,
    CASE 
        WHEN fp.Score > 0 THEN 'Positive'
        WHEN fp.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreEvaluation
FROM 
    FilteredPosts fp
LEFT JOIN 
    (SELECT 
        u.Id, u.Reputation 
     FROM 
        Users u 
     WHERE 
        u.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')) um ON um.Id = (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Id = fp.PostId
    )
LEFT JOIN 
    PostHistory ph ON ph.PostId = fp.PostId
WHERE 
    ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = fp.PostId)
ORDER BY 
    fp.ViewCount DESC
LIMIT 50;
