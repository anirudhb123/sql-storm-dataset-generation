WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- We are interested in questions only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
PopularTags AS (
    SELECT 
        TRIM(BOTH '<>' FROM UNNEST(STRING_TO_ARRAY(CAST(p.Tags AS TEXT), '><'))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5 -- Popular tags
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(b.Class) > 0
)
SELECT 
    up.UserId,
    up.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    pt.TagName,
    ur.TotalBadges
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    PopularTags pt ON pt.TagName = ANY(STRING_TO_ARRAY(rp.Tags, '><'))
JOIN 
    UserReputation ur ON ur.UserId = up.Id
WHERE 
    up.Reputation > 1000 -- Filter users with high reputation
    AND rp.PostRank <= 5 -- Top 5 posts per user
ORDER BY 
    rp.Score DESC, ur.TotalBadges DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

-- This query identifies the top posts from users with high reputation, considering their badge count, tags related to popular topics, 
-- and consolidates comments and scoring to showcase the most influential users and their contributions.
