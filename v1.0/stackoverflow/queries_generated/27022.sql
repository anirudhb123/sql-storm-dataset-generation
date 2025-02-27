WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- We only want questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Limit to past year
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_names ON true
    JOIN 
        Tags t ON t.TagName = tag_names
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryCount AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags edits
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    pt.TagList,
    ub.BadgeCount,
    COALESCE(phc.EditCount, 0) AS EditCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistoryCount phc ON rp.PostId = phc.PostId
WHERE 
    rp.RankByScore <= 5 -- Only get top 5 posts per user
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
