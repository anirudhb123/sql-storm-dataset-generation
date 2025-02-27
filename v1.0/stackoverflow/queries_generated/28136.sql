WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Focus on Questions
),
TagStats AS (
    SELECT 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Focus on Questions
    GROUP BY Tag
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
TopTags AS (
    SELECT 
        Tag, 
        PostCount, 
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
)
SELECT 
    u.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ut.Tag,
    ub.BadgeCount,
    ub.Badges
FROM 
    Users u
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
JOIN 
    TopTags tt ON tt.Tag = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rp.Rank <= 5 -- Top 5 Questions per User
    AND tt.TagRank <= 10 -- Top 10 Tags
ORDER BY 
    u.DisplayName, rp.Score DESC;
