
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS ViewRank,
        @prev_owner_user_id := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,  
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes  
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(ph.Comment SEPARATOR '; ') AS CloseReasons,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    rp.Upvotes,
    rp.Downvotes,
    COALESCE(cp.CloseCount, 0) AS ClosedCount,
    CASE 
        WHEN cp.CloseCount IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN rp.Upvotes > rp.Downvotes THEN 'Positive'
        WHEN rp.Upvotes < rp.Downvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    CASE 
        WHEN cp.CloseCount IS NULL AND (rp.ViewCount > 100 OR rp.CommentCount > 10) THEN 'Trending'
        ELSE 'Not Trending'
    END AS TrendingStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.ViewRank = 1 
    AND (
        (rp.CommentCount > 0 AND rp.Upvotes > 5) 
        OR (rp.Downvotes < 3 AND rp.ViewCount / NULLIF(rp.CommentCount, 0) < 10)
    )
ORDER BY 
    rp.ViewCount DESC, 
    rp.CommentCount DESC;
