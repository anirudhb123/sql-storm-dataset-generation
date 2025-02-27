WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(p.Views) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalTagViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalTagViews,
        RANK() OVER (ORDER BY TotalTagViews DESC) AS TagRank
    FROM 
        TagUsage
),
UserRanking AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        AcceptedAnswers,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
    FROM 
        UserPostStats
)
SELECT 
    u.DisplayName AS UserName,
    u.TotalPosts,
    u.Questions,
    u.Answers,
    u.AcceptedAnswers,
    u.TotalViews,
    u.TotalScore,
    tt.TagName,
    tt.PostCount AS TagPostCount,
    tt.TotalTagViews,
    CASE 
        WHEN u.UserRank <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributionLevel,
    tt.TagRank AS TagPopularityRank
FROM 
    UserRanking u
LEFT JOIN 
    TopTags tt ON tt.PostCount > 0
ORDER BY 
    u.TotalScore DESC, tt.TotalTagViews DESC
LIMIT 100;
