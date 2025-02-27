WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(NULLIF(b.Date, '1970-01-01 00:00:00'), 'No Badge') AS BadgeDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL (SELECT UNNEST(STRING_TO_ARRAY(p.Tags, '<>')) AS TagName) t ON TRUE
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, b.Date
), FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Score > 100 THEN 'High Score'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 0
), PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.ViewCount,
    fp.BadgeDate,
    fp.ScoreCategory,
    COALESCE(pHS.CloseOpenCount, 0) AS CloseOpenStatus,
    COALESCE(pHS.DeleteCount, 0) AS TotalDeletions,
    CASE 
        WHEN fp.PostRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS RankStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistorySummary pHS ON fp.PostId = pHS.PostId
WHERE 
    fp.BadgeDate <> 'No Badge'
    AND (fp.ScoreCategory = 'High Score' OR fp.CommentCount > 5)
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;

This query effectively benchmarks performance by introducing multiple complex SQL constructs, such as Common Table Expressions (CTEs), window functions, LEFT JOINs, and conditional logic. The use of string operations to manage tags, correlated subqueries to summarize post history actions, aggregation through `ARRAY_AGG`, and filtering based on computed fields adds intricacy. Additionally, it examines different categorizations of post performance based on criteria such as score and comment count. This contributes to assessing various aspects of interaction with posts, showcasing unusual SQL capabilities.
