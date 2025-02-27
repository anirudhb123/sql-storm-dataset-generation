WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS TotalWikis,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING(tag.TagName FROM 2 FOR LENGTH(tag.TagName) - 2)) AS Tag,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    CROSS JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, '><')) AS tag
    GROUP BY 
        tag.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
UserBadgeCount AS (
    SELECT 
        u.Id AS User_id,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.Reputation,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalWikis,
    ups.AcceptedAnswers,
    ubc.TotalBadges,
    pt.Tag,
    pt.PostCount
FROM 
    UserPostStats ups
JOIN 
    UserBadgeCount ubc ON ups.UserId = ubc.User_id
JOIN 
    PopularTags pt ON pt.PostCount = (SELECT MAX(PostCount) FROM PopularTags)
WHERE 
    ups.Reputation > 1000
ORDER BY 
    ups.Reputation DESC, ups.TotalPosts DESC;
