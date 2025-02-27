WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.Score > 10
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    pt.PostCount AS RelatedPosts,
    ub.BadgeNames,
    u.Reputation,
    COALESCE(psh.CloseCount, 0) AS ClosedPosts,
    COALESCE(psh.ReopenCount, 0) AS ReopenedPosts
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (SELECT unnest(string_to_array(rp.Tags, ',')))
LEFT JOIN 
    UserBadges ub ON ub.UserId = rp.OwnerUserId
LEFT JOIN 
    Users u ON u.Id = rp.OwnerUserId
LEFT JOIN 
    PostHistorySummary psh ON psh.PostId = rp.Id
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;
