WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AcceptedAnswerId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        ph.Text,
        PHU1.UserDisplayName AS ReopenUser
    FROM 
        PostHistory ph
    LEFT JOIN 
        Users PHU1 ON PHU1.Id = ph.UserId 
                   AND ph.PostHistoryTypeId IN (11, 10)  -- Reopen/Close reasons
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    CASE 
        WHEN php.PostHistoryTypeId IS NOT NULL THEN 'Closed/Reopened'
        ELSE 'Active'
    END AS PostStatus,
    STRING_AGG(DISTINCT CONCAT(ph.UserDisplayName, ' (', ph.Comment, ')'), '; ') AS HistoryComments
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails php ON rp.PostId = php.PostId
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.CommentCount, php.PostHistoryTypeId
HAVING 
    COUNT(DISTINCT php.PostHistoryTypeId) FILTER (WHERE php.PostHistoryTypeId IS NOT NULL) > 0
ORDER BY 
    rp.Score DESC,
    rp.ViewCount DESC
LIMIT 100
OFFSET 0;
This query constructs a detailed representation of the most active posts in the last year, incorporating various SQL features including CTEs, window functions, and conditional logic, while ensuring edge cases about post closure are addressed with clear semantic determinations. It provides a rich insight into the state and history of the posts, making it suitable for performance benchmarking.
