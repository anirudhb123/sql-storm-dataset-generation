WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(P.Id) AS TotalPosts, 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredPosts,
        AVG(P.ViewCount) AS AverageViewCount,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),

TopQuestions AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Score, 
        P.ViewCount, 
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1
    ORDER BY 
        P.Score DESC
    LIMIT 10
),

TaggedPostStats AS (
    SELECT 
        TagName,
        COUNT(P.Id) AS TotalPostsWithTag,
        AVG(P.ViewCount) AS AverageViewCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        TagName
)

SELECT 
    U.UserId, 
    U.DisplayName, 
    U.TotalPosts, 
    U.TotalQuestions, 
    U.TotalAnswers, 
    U.PositiveScoredPosts, 
    U.AverageViewCount,
    U.AverageScore,
    T.Title AS TopQuestionTitle,
    T.Score AS TopQuestionScore,
    T.ViewCount AS TopQuestionViewCount,
    T.OwnerDisplayName AS TopQuestionOwner,
    T2.TagName, 
    T2.TotalPostsWithTag,
    T2.AverageViewCount AS AverageViewCountForTag
FROM 
    UserPostStats U
LEFT JOIN 
    TopQuestions T ON U.TotalQuestions > 0
LEFT JOIN 
    TaggedPostStats T2 ON U.TotalPosts > 0
ORDER BY 
    U.Reputation DESC;
