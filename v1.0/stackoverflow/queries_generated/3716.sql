WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions only
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.QuestionsAsked,
    us.TotalScore,
    us.TotalBadges,
    rp.Title AS TopPostTitle,
    rp.CreationDate AS TopPostDate,
    pt.Tag,
    pt.TagCount
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.PostRank = 1
CROSS JOIN 
    PopularTags pt
WHERE 
    us.TotalScore > 100
ORDER BY 
    us.TotalScore DESC, us.QuestionsAsked DESC
OFFSET 5 LIMIT 10;
