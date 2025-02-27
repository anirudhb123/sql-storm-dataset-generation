WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS rn,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COALESCE(NULLIF(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0), 0) AS DownVoteCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closing and reopening history
    GROUP BY 
        ph.PostId, ph.CreationDate
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.CommentCount,
        cp.CloseReasons,
        CASE 
            WHEN cp.CloseReasons IS NOT NULL THEN TRUE 
            ELSE FALSE 
        END AS IsClosed,
        CASE 
            WHEN rp.UpVoteCount - rp.DownVoteCount > 10 THEN 'Highly Upvoted'
            WHEN rp.UpVoteCount - rp.DownVoteCount BETWEEN 1 AND 10 THEN 'Moderately Upvoted'
            WHEN rp.UpVoteCount - rp.DownVoteCount < 0 THEN 'Downvoted'
            ELSE 'Neutral'
        END AS VoteStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    fr.UpVoteCount,
    fr.DownVoteCount,
    fr.CommentCount,
    fr.CloseReasons,
    fr.IsClosed,
    fr.VoteStatus,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = p.OwnerUserId) AS BadgeCount
FROM 
    FinalResults fr
JOIN 
    Posts p ON fr.PostId = p.Id
WHERE 
    (UPPER(fr.Title) LIKE '%SQL%' OR 
     LOWER(fr.CloseReasons) LIKE '%duplicate%')
    AND (p.CreationDate >= NOW() - INTERVAL '1 year')
ORDER BY 
    fr.Score DESC, fr.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;  -- Result Pagination
