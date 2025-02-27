
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
), 
PostDetails AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        ur.Reputation,
        COALESCE(cp.CloseCount, 0) AS CloseCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Reputation,
    pd.CloseCount,
    CASE 
        WHEN pd.CloseCount > 0 THEN 'Closed' 
        ELSE 'Active' 
    END AS PostStatus,
    GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
FROM 
    PostDetails pd
LEFT JOIN 
    Posts p ON pd.PostId = p.Id
LEFT JOIN 
    (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag
     FROM 
         (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
          UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
     WHERE 
         numbers.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS tag ON TRUE
LEFT JOIN 
    Tags t ON LOWER(tag.tag) = LOWER(t.TagName)
WHERE 
    pd.Reputation > 1000
GROUP BY 
    pd.PostId, pd.Title, pd.Reputation, pd.CloseCount
ORDER BY 
    pd.Reputation DESC, pd.CloseCount DESC;
