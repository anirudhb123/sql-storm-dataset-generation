WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '>')) AS Tag
    FROM 
        Posts
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCounts
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    COALESCE(up.Reputation, 0) AS UserReputation,
    COALESCE(up.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(cp.CloseCounts, 0) AS CloseCount,
    pt.Tag
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation up ON u.Id = up.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
JOIN 
    PopularTags pt ON pt.Tag IN (SELECT DISTINCT UNNEST(string_to_array(rp.Tags, '>')) FROM Posts WHERE rp.PostId = Id)
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;
