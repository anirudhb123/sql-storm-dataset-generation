WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 0
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.UserId) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed' ELSE 'Open' END, ', ') AS PostStatus
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    p.ViewCount,
    p.Score,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    phs.EditCount,
    phs.LastEditDate,
    phs.PostStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.Id = phs.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    p.Score DESC,
    u.Reputation DESC
LIMIT 50;

WITH RecursiveTagCounts AS (
    SELECT 
        TagName, 
        COUNT(*) AS Count
    FROM 
        Posts p 
    CROSS JOIN LATERAL 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName, 
        Count,
        ROW_NUMBER() OVER (ORDER BY Count DESC) AS TagRank
    FROM 
        RecursiveTagCounts
)
SELECT 
    tt.TagName,
    tt.Count,
    CASE 
        WHEN tt.Count > 100 THEN 'Highly Popular'
        WHEN tt.Count BETWEEN 50 AND 100 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS TagPopularity
FROM 
    TopTags tt
WHERE 
    tt.TagRank <= 10
ORDER BY 
    tt.Count DESC;

SELECT 
    DISTINCT 
        ph.UserId AS EditorUserId,
        u.DisplayName AS EditorDisplayName,
        STRING_AGG(DISTINCT p.Title || ' (' || ph.CreationDate || ')', ', ') AS EditedPosts
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    Users u ON ph.UserId = u.Id
WHERE 
    ph.CreationDate >= NOW() - INTERVAL '30 days'
    AND ph.PostHistoryTypeId IN (4, 5)  -- Title and Body edits
GROUP BY 
    ph.UserId, u.DisplayName
HAVING 
    COUNT(p.Id) > 5 -- Editors with more than 5 edits
ORDER BY 
    COUNT(p.Id) DESC;
