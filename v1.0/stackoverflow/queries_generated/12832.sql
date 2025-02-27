-- Performance Benchmarking Query
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON T.Id = ANY(string_to_array(P.Tags, ',')::int[])
    GROUP BY 
        T.TagName
),
PostHistoryStats AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS TotalEdits,
        COUNT(DISTINCT PH.PostId) AS UniquePostsEdited
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.TotalViews,
    U.TotalScore,
    U.AverageScore,
    T.PostCount AS TagPostCount,
    T.TotalScore AS TagTotalScore,
    PH.TotalEdits,
    PH.UniquePostsEdited
FROM 
    UserPostStats U
LEFT JOIN 
    TagStats T ON U.TotalPosts > 0
LEFT JOIN 
    PostHistoryStats PH ON U.UserId = PH.UserId
ORDER BY 
    U.TotalPosts DESC
LIMIT 100;
