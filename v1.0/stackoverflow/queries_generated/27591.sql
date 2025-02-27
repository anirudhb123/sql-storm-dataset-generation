WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(TRIM(BOTH '<>' FROM unnest(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '>'))), ', ') AS TagsList
    FROM 
        Posts p
    GROUP BY 
        p.Id
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId AS UserId,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ub.TotalBadges,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    pt.TagsList,
    ra.LastActivityDate
FROM 
    UserPostStats ups
LEFT JOIN 
    UserBadges ub ON ups.UserId = ub.UserId
LEFT JOIN 
    PostTags pt ON EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = ups.UserId AND p.Id = pt.PostId)
LEFT JOIN 
    RecentActivity ra ON ups.UserId = ra.UserId
WHERE 
    ups.TotalPosts > 0
ORDER BY 
    ups.TotalPosts DESC, ups.TotalQuestions DESC, ub.TotalBadges DESC;
