WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        ph.PostId
),
HighScoreTags AS (
    SELECT 
        p.Id AS PostId,
        t.TagName,
        COUNT(t.TagName) AS TagCount
    FROM 
        Posts p
    JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tags ON t.TagName = tags
    JOIN 
        Tags t ON t.Id = tags.Id
    WHERE 
        p.Score > 50
    GROUP BY 
        p.Id, t.TagName
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    r.Title,
    COALESCE(r.CreationDate, 'No Posts') AS LastPostDate,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ub.BadgeNames, 'No Badges') AS Badges,
    COALESCE(rh.HistoryTypes, 'No History') AS RecentHistory,
    COALESCE(rh.HistoryCount, 0) AS Last30DayHistoryCount,
    COALESCE(ht.TagCount, 0) AS HighScoreTagsCount
FROM 
    Users u
LEFT JOIN 
    RankedPosts r ON u.Id = r.OwnerUserId AND r.rn = 1
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RecentPostHistory rh ON r.PostId = rh.PostId
LEFT JOIN 
    HighScoreTags ht ON r.PostId = ht.PostId
WHERE 
    u.Reputation > 100
ORDER BY 
    u.Reputation DESC, 
    r.Score DESC
LIMIT 50
OFFSET 10;
