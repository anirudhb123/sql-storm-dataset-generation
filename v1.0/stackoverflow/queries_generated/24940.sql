WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
          AND p.ViewCount > 100
)

SELECT 
    up.DisplayName,
    up.Reputation,
    rp.Title,
    rp.Score,
    rp.CommentCount,
    ph.Comment AS CloseReason,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.AcceptedAnswerId = up.Id
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId 
                     AND ph.PostHistoryTypeId = 10 
                     AND ph.CreationDate = (SELECT MAX(CreationDate)
                                             FROM PostHistory 
                                             WHERE PostId = rp.PostId 
                                             AND PostHistoryTypeId = 10)
LEFT JOIN 
    (SELECT 
         post_id, 
         UNNEST(string_to_array(Tags, '><')) AS TagName
     FROM 
         Posts) t ON t.post_id = rp.PostId
WHERE 
    rp.rn <= 3
    AND (ph.Comment IS NOT NULL OR rp.Score > 50)
GROUP BY 
    up.DisplayName, up.Reputation, rp.Title, rp.Score, rp.CommentCount, ph.Comment
ORDER BY 
    rp.Score DESC
LIMIT 10;

-- Additional complexity: 
-- We can introduce a bizarre edge case by checking for NULL values in aggregated fields
HAVING 
    COUNT(DISTINCT t.TagName) IS NULL OR COUNT(DISTINCT t.TagName) > 5;
