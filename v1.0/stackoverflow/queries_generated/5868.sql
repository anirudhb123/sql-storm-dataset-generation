WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostsCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    GROUP BY 
        t.TagName
    ORDER BY 
        PostsCount DESC
    LIMIT 5
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    u.DisplayName AS TopUser,
    u.PostsCount,
    u.AnswersCount,
    u.TotalScore,
    u.TotalBounty,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    t.TagName AS PopularTag,
    t.PostsCount AS TagPostsCount
FROM 
    TopUsers u
CROSS JOIN 
    PopularTags t
WHERE 
    u.Rank <= 10 -- Limiting to top 10 users
ORDER BY 
    u.TotalScore DESC, t.PostsCount DESC;
