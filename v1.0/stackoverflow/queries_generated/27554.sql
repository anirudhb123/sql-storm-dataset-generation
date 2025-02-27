WITH TagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1 
    GROUP BY 
        u.Id
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        u.DisplayName AS Author,
        tc.TagCount,
        tc.Tags,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        TagCounts tc ON tc.PostId = p.Id
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.Score > 10 -- Filtering for popular posts
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.BadgeCount,
    up.QuestionCount,
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.TagCount,
    pp.Tags
FROM 
    UserReputation up
JOIN 
    PopularPosts pp ON pp.Author = up.DisplayName
ORDER BY 
    up.Reputation DESC, pp.Score DESC;
