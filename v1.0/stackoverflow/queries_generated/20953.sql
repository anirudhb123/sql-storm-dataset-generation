WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '1 year')
    GROUP BY 
        p.Id
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.Rank,
        rp.CommentCount,
        u.DisplayName AS AuthorDisplayName,
        u.Reputation
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        rp.Rank <= 10
), 
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (13, 12) THEN ph.CreationDate END) AS LastUndeleted
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
), 
PostLinkSummary AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    COALESCE(pls.RelatedPostCount, 0) AS RelatedPosts,
    COALESCE(phs.LastClosed, phs.LastUndeleted, 'Not applicable') AS ClosureStatus,
    tp.AuthorDisplayName,
    tp.Reputation
FROM 
    TopPosts tp
LEFT JOIN 
    PostLinkSummary pls ON tp.PostId = pls.PostId
LEFT JOIN 
    PostHistorySummary phs ON tp.PostId = phs.PostId
ORDER BY 
    tp.ViewCount DESC, 
    tp.Score DESC
LIMIT 100;

-- Note: Handles NULL logic by using COALESCE for closure status and related post counts
-- Uses window functions for ranking and aggregations
-- Incorporates multiple CTEs to gather and summarize data from various tables:
-- Posts, Comments, Users, PostHistory, and PostLinks for a comprehensive report
