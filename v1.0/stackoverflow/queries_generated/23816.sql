WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  -- Only Questions and Answers
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        c.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    u.DisplayName AS OwnerName,
    COALESCE(cp.ClosedDate, 'Not Closed') AS ClosureDate,
    COALESCE(cp.CloseReason, 'N/A') AS ClosureReason
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    ClosedPostDetails cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank <= 5
    AND COALESCE(cp.ClosedDate IS NOT NULL, FALSE) = FALSE  -- Include only non-closed posts
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 10;

-- Additional analysis example
WITH CommentCounts AS (
    SELECT 
        PostId, 
        COUNT(*) AS TotalComments 
    FROM 
        Comments 
    GROUP BY 
        PostId
)
SELECT 
    p.Title,
    COALESCE(cc.TotalComments, 0) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    CommentCounts cc ON p.Id = cc.PostId
WHERE 
    p.AnswerCount > (SELECT AVG(AnswerCount) FROM Posts)  -- Above average answers
    AND NOT EXISTS (
        SELECT 1
        FROM PostHistory ph
        WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 12)  -- Not closed or deleted
    )
ORDER BY 
    p.AnswerCount DESC
FETCH FIRST 5 ROWS ONLY;

-- Edge case: Handling NO results in SELECT
SELECT 
    COALESCE((SELECT COUNT(*) FROM Posts WHERE ViewCount = 0), 'No Posts with zero views found!') AS PostCountMessage;
