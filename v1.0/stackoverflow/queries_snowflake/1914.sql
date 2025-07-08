
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
    LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
FROM 
    PostDetails pd
LEFT JOIN 
    Posts p ON pd.PostId = p.Id
LEFT JOIN 
    LATERAL (SELECT TRIM(REGEXP_SUBSTR(p.Tags, '[^><]+', 1, seq)) AS tag 
               FROM TABLE(GENERATOR(ROWCOUNT => REGEXP_COUNT(p.Tags, '><') + 1)) seq
               WHERE TRIM(REGEXP_SUBSTR(p.Tags, '[^><]+', 1, seq)) IS NOT NULL) AS tag ON TRUE
LEFT JOIN 
    Tags t ON LOWER(tag.tag) = LOWER(t.TagName)
WHERE 
    pd.Reputation > 1000
GROUP BY 
    pd.PostId, pd.Title, pd.Reputation, pd.CloseCount
ORDER BY 
    pd.Reputation DESC, pd.CloseCount DESC;
