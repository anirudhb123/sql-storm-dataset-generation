WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  -- Considering only Questions and Answers
),
PostCommentCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),
PostHistoryStats AS (
    SELECT 
        PostId,
        MAX(CASE WHEN PostHistoryTypeId = 10 THEN CreationDate END) AS LastClosedDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId IN (10, 11, 12, 14) -- Considering close, reopen, delete, edit types
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    pcc.CommentCount,
    COALESCE(PHS.LastClosedDate, 'Never Closed') AS LastClosedDate,
    PHS.EditCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostCommentCounts pcc ON rp.PostId = pcc.PostId
LEFT JOIN 
    PostHistoryStats PHS ON rp.PostId = PHS.PostId
WHERE 
    rp.Rank <= 10  -- Get top 10 posts per type
ORDER BY 
    rp.PostTypeId, 
    rp.Rank;
