WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COALESCE(p.ParentId, 0) AS IsAnswer,
        ARRAY_AGG(DISTINCT SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2) ) AS TagsArray
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2)  -- 1 for Questions, 2 for Answers
    GROUP BY 
        p.Id, p.OwnerUserId
),

CommentedPosts AS (
    SELECT
        r.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        RankedPosts r
    LEFT JOIN Comments c ON r.PostId = c.PostId
    GROUP BY 
        r.PostId
),

PostWithHistory AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        cp.CommentCount,
        cp.LastCommentDate,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Other'
        END AS PostAction
    FROM 
        RankedPosts rp
    LEFT JOIN Comments c ON rp.PostId = c.PostId
    LEFT JOIN PostHistory ph ON rp.PostId = ph.PostId
    LEFT JOIN CommentedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        ph.PostHistoryTypeId IS NOT NULL
)

SELECT 
    p.Title,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    COALESCE(p.LastCommentDate, 'No Comments') AS LastCommented,
    STRING_AGG(DISTINCT p.TagsArray, ', ') AS Tags,
    STRING_AGG(DISTINCT CONCAT_WS(' - ', p.UserDisplayName, p.PostAction, to_char(p.HistoryDate, 'YYYY-MM-DD'))) AS Actions
FROM 
    PostWithHistory p
WHERE 
    p.CommentCount > 0 OR p.PostAction IS NOT NULL
GROUP BY 
    p.Title, p.Score, p.ViewCount, p.CommentCount
HAVING 
    SUM(CASE WHEN p.PostAction = 'Closed' THEN 1 ELSE 0 END) > 0
    AND COUNT(p.PostId) > 1
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
