WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopVotedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.Score > 0
    ORDER BY 
        P.Score DESC
    LIMIT 5
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 0
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalAcceptedAnswers,
    T.PostId,
    T.Title AS TopVotedPostTitle,
    T.Score AS TopVotedPostScore,
    T.OwnerDisplayName,
    Tg.TagName,
    Tg.PostCount,
    Tg.PopularPosts
FROM 
    UserStats U
CROSS JOIN 
    TopVotedPosts T
JOIN 
    TagStats Tg ON Tg.PopularPosts > 0
ORDER BY 
    U.Reputation DESC, 
    T.Score DESC;
