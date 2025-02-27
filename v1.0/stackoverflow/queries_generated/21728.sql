WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year' 
    AND 
        p.Score IS NOT NULL
),
RecentComments AS (
    SELECT 
        c.PostId,
        c.CreationDate AS CommentDate,
        COUNT(*) AS CommentsCount,
        STRING_AGG(c.Text, ' | ') AS AllComments
    FROM 
        Comments c
    WHERE 
        c.CreationDate > CURRENT_DATE - INTERVAL '6 months' 
    GROUP BY 
        c.PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CreationDate,
    rc.CommentsCount,
    rc.AllComments,
    phs.CloseReopenCount,
    phs.DeleteUndeleteCount,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        ELSE 'Has Score'
    END AS Score_Status,
    COALESCE(ROUND(rp.Score / NULLIF(rp.ViewCount, 0), 2), 0) AS Score_per_View
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentComments rc ON rp.PostId = rc.PostId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC;

-- Additional complexity can be added by using set operations or further filtering.
WITH FilteredPosts AS (
    SELECT p.*, 
           CASE 
               WHEN p.ViewCount IS NULL OR p.ViewCount = 0 THEN 'No Views Yet'
               ELSE NULL
           END AS ViewCount_Status
    FROM 
        Posts p
    WHERE 
        EXISTS (
            SELECT 1 
            FROM Votes v 
            WHERE v.PostId = p.Id 
              AND v.VoteTypeId IN (2, 3) 
              AND v.CreationDate > CURRENT_DATE - INTERVAL '3 months'
        )
)
SELECT * FROM FilteredPosts
WHERE 
    (ViewCount_Status IS NOT NULL OR AnswerCount > 0)
UNION 
SELECT 
    DISTINCT rp.*, 
    NULL AS ViewCount_Status
FROM 
    RankedPosts rp
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM Comments c 
        WHERE c.PostId = rp.PostId
    )
ORDER BY 
    CreationDate DESC;
