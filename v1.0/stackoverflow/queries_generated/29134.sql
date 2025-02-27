WITH TagStatistics AS (
    SELECT 
        TagName,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS Wikis,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM 
        Posts
    JOIN 
        Tags ON Tags.Id = ANY(string_to_array(substring(Tags, 2, length(Tags)-2), '><')::int[])
    GROUP BY 
        TagName
),
UserStatistics AS (
    SELECT 
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS TotalWikis,
        SUM(P.Views) AS TotalViews,
        AVG(U.Reputation) AS AverageReputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.DisplayName 
),
CombinedStatistics AS (
    SELECT 
        T.TagName,
        T.TotalPosts,
        T.Questions,
        T.Answers,
        T.Wikis,
        T.TotalViews,
        T.AverageScore,
        U.DisplayName,
        U.TotalPosts AS UserTotalPosts,
        U.TotalQuestions AS UserTotalQuestions,
        U.TotalAnswers AS UserTotalAnswers,
        U.TotalWikis AS UserTotalWikis,
        U.TotalViews AS UserTotalViews,
        U.AverageReputation
    FROM 
        TagStatistics T
    JOIN 
        UserStatistics U ON T.TotalPosts = U.TotalPosts
    ORDER BY 
        T.TotalPosts DESC, U.AverageReputation DESC
)
SELECT 
    TagName,
    TotalPosts,
    Questions,
    Answers,
    Wikis,
    TotalViews,
    AverageScore,
    DisplayName,
    UserTotalPosts,
    UserTotalQuestions,
    UserTotalAnswers,
    UserTotalWikis,
    UserTotalViews,
    AverageReputation
FROM 
    CombinedStatistics
WHERE 
    TotalPosts > 10
LIMIT 50;
