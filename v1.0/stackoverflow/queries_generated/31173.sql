WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS TagName,
        COUNT(p.Id) AS TagCount
    FROM 
        Posts p
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName AS UserName,
    r.PostId,
    r.Title,
    r.Score,
    r.ViewCount,
    r.CommentCount,
    ub.BadgeCount,
    ub.Badges,
    COALESCE(pht.HistoryCount, 0) AS PostHistoryCount,
    pt.TagName
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryStats pht ON r.PostId = pht.PostId
LEFT JOIN 
    PopularTags pt ON pt.TagName = ANY(STRING_TO_ARRAY(r.Tags, ','))
WHERE 
    r.PostRank = 1
ORDER BY 
    u.Reputation DESC,
    r.Score DESC,
    r.ViewCount DESC;
