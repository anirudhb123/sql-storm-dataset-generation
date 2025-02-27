WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 10
    AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation IS NOT NULL
    GROUP BY 
        u.Id
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        string_agg(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_name ON true
    JOIN 
        Tags t ON t.TagName = tag_name
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    rp.Title AS LatestPostTitle,
    rp.CreationDate,
    rp.Score,
    pt.Tags,
    CASE 
        WHEN u.Reputation > 1000 THEN 'High Reputation User'
        WHEN u.Reputation >= 500 THEN 'Medium Reputation User'
        ELSE 'Low Reputation User' 
    END AS UserCategory,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Latest Post'
        ELSE null 
    END AS RankStatus
FROM 
    UserReputation u
LEFT JOIN 
    RankedPosts rp ON u.UserId = rp.OwnerUserId
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    u.PostCount >= 5
ORDER BY 
    u.Reputation DESC,
    rp.CreationDate DESC
LIMIT 10;

-- Consider corner cases for NULL handling
-- Investigate if Default Tags exist for posts with NULL Tags
SELECT 
    COUNT(p.Id) AS PostsWithDefaultTags
FROM 
    Posts p
LEFT JOIN 
    PostTags pt ON p.Id = pt.PostId
WHERE 
    pt.Tags IS NULL
AND 
    p.Tags IS NOT NULL 
AND 
    TRIM(p.Tags) = '';

-- Coalesce tag-related strings to ensure no nulls are presented
SELECT 
    p.Id,
    COALESCE(pt.Tags, 'No Tags') AS TagsSummary,
    COUNT(p.Id) OVER (PARTITION BY pt.Tags)
FROM 
    Posts p
LEFT JOIN 
    PostTags pt ON p.Id = pt.PostId
ORDER BY 
    p.Id;
