WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.Tags,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END) AS DeletionDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS CloseCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.Id END) AS ReopenCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        ph.PostId
),
FinalData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.CreationDate,
        pd.DeletionDate,
        pd.LastEditDate,
        pd.CloseCount,
        pd.ReopenCount,
        rp.Rank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryData pd ON rp.PostId = pd.PostId
)
SELECT 
    PostId,
    Title,
    Score,
    ViewCount,
    Tags,
    CreationDate,
    LastEditDate,
    CASE 
        WHEN DeletionDate IS NOT NULL THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus,
    CloseCount,
    ReopenCount,
    Rank
FROM 
    FinalData
WHERE 
    Rank <= 10
ORDER BY 
    CreationDate DESC, 
    Score DESC
UNION ALL
SELECT
    NULL AS PostId,
    'Summary' AS Title,
    COUNT(*) AS Score,
    SUM(ViewCount) AS ViewCount,
    NULL AS Tags,
    NULL AS CreationDate,
    NULL AS LastEditDate,
    NULL AS PostStatus,
    SUM(CloseCount) AS CloseCount,
    SUM(ReopenCount) AS ReopenCount,
    NULL AS Rank
FROM 
    FinalData
WHERE 
    CloseCount + ReopenCount > 0;
