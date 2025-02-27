
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        LEN(p.Tags) - LEN(REPLACE(p.Tags, '> <', '')) + 1 AS TagCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM PostHistory ph 
            WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId = 10
        ), 0) AS CloseCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM PostHistory ph 
            WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11) 
        ), 0) AS ClosureReopenCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.ViewCount > 100
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.AnswerCount,
    pd.CommentCount,
    pd.Tags,
    pd.OwnerDisplayName,
    pd.TagCount,
    pd.CloseCount,
    pd.ClosureReopenCount,
    CASE 
        WHEN pd.CloseCount > 0 THEN 'Closed'
        WHEN pd.ClosureReopenCount > 0 THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus,
    DATEDIFF(HOUR, pd.CreationDate, '2024-10-01 12:34:56') AS HoursSinceCreation,
    pd.TagCount * pd.Score AS TagScoreImpact
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC,
    pd.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
