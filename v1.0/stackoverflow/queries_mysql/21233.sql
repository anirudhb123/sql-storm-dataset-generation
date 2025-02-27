
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        @row_num := IF(@current_user = p.OwnerUserId, @row_num + 1, 1) AS UserPostRank,
        @current_user := p.OwnerUserId,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId,
        (SELECT @row_num := 0, @current_user := NULL) AS vars
    WHERE
        p.PostTypeId IN (1, 2)  
),
RecentEdits AS (
    SELECT
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.UserId AS EditorId,
        p.OwnerUserId,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS EditCount
    FROM
        PostHistory ph
    INNER JOIN
        Posts p ON ph.PostId = p.Id
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6)  
)
SELECT
    rp.Title,
    rp.CreationDate,
    rp.LastActivityDate,
    u.DisplayName AS OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    COALESCE(re.EditCount, 0) AS EditCount,
    CASE
        WHEN rp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus,
    CASE
        WHEN MAX(rp.ViewCount) OVER () < 100 THEN 'Low Engagement'
        WHEN MAX(rp.ViewCount) OVER () >= 100 AND MAX(rp.ViewCount) OVER () < 1000 THEN 'Moderate Engagement'
        ELSE 'High Engagement'
    END AS EngagementLevel
FROM
    RankedPosts rp
LEFT JOIN
    RecentEdits re ON rp.PostId = re.PostId
LEFT JOIN
    Users u ON rp.OwnerUserId = u.Id
WHERE
    rp.UserPostRank = 1  
    AND (re.EditCount IS NULL OR re.EditCount > 2)  
GROUP BY
    rp.Title, 
    rp.CreationDate, 
    rp.LastActivityDate, 
    u.DisplayName, 
    rp.Score, 
    rp.ViewCount, 
    re.EditCount, 
    rp.CommentCount
ORDER BY
    rp.Score DESC,
    rp.ViewCount DESC;
