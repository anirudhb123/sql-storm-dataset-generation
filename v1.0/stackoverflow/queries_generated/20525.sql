WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL (
            SELECT 
                UNNEST(string_to_array(p.Tags, '><')) AS TagName
        ) t ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.Reputation
),

PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) OVER (PARTITION BY ph.PostId) AS CloseReopenCount,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LastActivity
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Reputation,
    rp.Rank,
    rp.CommentCount,
    rp.Tags,
    COALESCE(pht.CloseReopenCount, 0) AS CloseReopenCount,
    CASE 
        WHEN pht.LastActivity IS NULL THEN 'No Activity' 
        ELSE to_char(pht.LastActivity, 'YYYY-MM-DD HH24:MI:SS')
    END AS LastActivity
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryCTE pht ON rp.PostId = pht.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.CommentCount DESC,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 0 
        ELSE rp.ViewCount 
    END DESC;
