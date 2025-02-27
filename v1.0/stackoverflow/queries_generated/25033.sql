WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]) 
    WHERE 
        p.PostTypeId = 1 -- We are only interested in Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),

PostHistoryAggregation AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS SuggestedEditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    rp.CommentCount,
    rp.AnswerCount,
    ph.CloseCount,
    ph.ReopenCount,
    ph.DeleteUndeleteCount,
    ph.SuggestedEditCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAggregation ph ON rp.PostId = ph.PostId
WHERE 
    rp.ViewRank <= 100 -- Limit to top 100 by views
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
