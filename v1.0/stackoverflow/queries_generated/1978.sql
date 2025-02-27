WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(NULLIF(u.DisplayName, ''), 'Anonymous') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY TAGS.TagName ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN 
        (SELECT DISTINCT unnest(string_to_array(Tags, '><')) AS TagName FROM Posts) AS TAGS
    WHERE 
        p.PostTypeId = 1
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
),
UserBadges AS (
    SELECT 
        u.Id,
        COUNT(*) AS BadgeCount
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    COALESCE(cp.ClosedDate, 'Not Closed') AS ClosedDate,
    COALESCE(cp.ClosedBy, 'N/A') AS ClosedBy,
    ub.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.Id
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.Id
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
