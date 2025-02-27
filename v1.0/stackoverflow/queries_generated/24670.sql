WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        b.Class AS BadgeClass,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, b.Class
),
UserPostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.Score IS NULL THEN 0 ELSE p.Score END) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
RelevantUserData AS (
    SELECT 
        ub.UserId,
        ub.Reputation,
        ub.TotalBadges,
        ub.BadgeNames,
        up.TotalPosts,
        up.TotalQuestions,
        up.TotalAnswers,
        up.TotalScore
    FROM 
        UserBadges ub
    JOIN 
        UserPostActivity up ON ub.UserId = up.OwnerUserId
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostsCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        TotalViews,
        DENSE_RANK() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        TagStatistics
    WHERE 
        TotalViews > 1000
)

SELECT 
    u.UserId,
    u.Reputation,
    u.TotalBadges,
    u.BadgeNames,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalScore,
    t.TagName,
    t.TotalViews,
    CASE 
        WHEN u.TotalPosts > 50 THEN 'Active User'
        WHEN u.Reputation > 1000 THEN 'Experienced User'
        ELSE 'New User'
    END AS UserCategory,
    COALESCE(1.0 * u.TotalScore / NULLIF(u.TotalPosts, 0), 0) AS AverageScorePerPost,
    CASE 
        WHEN t.Rank IS NOT NULL THEN t.Rank 
        ELSE (SELECT COUNT(*) + 1 FROM TagStatistics) 
    END AS TagRank
FROM 
    RelevantUserData u
LEFT JOIN 
    TopTags t ON EXISTS (SELECT 1 FROM STRING_TO_ARRAY(u.BadgeNames, ', ') AS badges WHERE badges[1] = t.TagName)
WHERE 
    u.Reputation > 500 
ORDER BY 
    u.TotalScore DESC, u.Reputation DESC;
