WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(SUM(v.BountyAmount) FILTER (WHERE v.VoteTypeId = 9), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostHistoryAggregated AS (
   SELECT 
       ph.PostId,
       MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
       MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS IsReopened,
       COUNT(DISTINCT ph.UserId) AS EditCount
   FROM 
       PostHistory ph
   WHERE 
       ph.CreationDate > NOW() - INTERVAL '1 year'
   GROUP BY 
       ph.PostId
)
SELECT 
    up.DisplayName AS User,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    pha.IsClosed,
    pha.IsReopened,
    pha.EditCount,
    CASE 
        WHEN pha.IsClosed = 1 AND pha.IsReopened = 1 THEN 'Closed and Reopened'
        WHEN pha.IsClosed = 1 THEN 'Closed'
        WHEN pha.IsReopened = 1 THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus,
    'Bounty: ' || COALESCE(rp.TotalBounty::text, '0') AS BountyInfo,
    string_agg(DISTINCT CASE WHEN t.TagName IS NOT NULL THEN t.TagName ELSE '<No Tag>' END, ', ') AS Tags
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.PostId IN (SELECT DISTINCT p.Id FROM Posts p WHERE p.OwnerUserId = up.Id) 
LEFT JOIN 
    PostHistoryAggregated pha ON rp.PostId = pha.PostId
LEFT JOIN 
    Posts p2 ON rp.PostId = p2.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(p2.Tags, ',')) AS TagName
    ) t ON true
WHERE 
    rp.PostRank = 1
GROUP BY 
    up.DisplayName, rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, pha.IsClosed, pha.IsReopened, pha.EditCount
ORDER BY 
    rp.ViewCount DESC NULLS LAST, rp.Score DESC, up.DisplayName
LIMIT 100;
