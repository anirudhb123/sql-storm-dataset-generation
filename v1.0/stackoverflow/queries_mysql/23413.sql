
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE((
            SELECT COUNT(*)
            FROM Comments c
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByType,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS MostActivePostForUser
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR) 
        AND p.Score >= 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(ph.Comment SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    COALESCE(cp.CloseReasons, 'Not Closed') AS CloseReasons,
    CASE 
        WHEN rp.RankByType <= 5 THEN 'Hot Post'
        WHEN rp.MostActivePostForUser = 1 THEN 'User''s Most Active Post'
        ELSE 'Regular Post'
    END AS PostStatus,
    GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
        JOIN 
            Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) t ON t.TagName IS NOT NULL
WHERE 
    rp.CommentCount > 3 
    OR (cp.CloseReasons IS NOT NULL AND rp.Score < 5)
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, 
    rp.CommentCount, cp.CloseReasons, rp.RankByType, 
    rp.MostActivePostForUser
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC
LIMIT 100;
