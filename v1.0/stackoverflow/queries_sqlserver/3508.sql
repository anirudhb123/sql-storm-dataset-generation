
WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 2 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, '><') 
    WHERE 
        Posts.PostTypeId = 1
    GROUP BY 
        value
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserStats
    WHERE 
        TotalPosts > 10
)
SELECT
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.AcceptedAnswers,
    COALESCE(T.TagName, 'No Tags') AS TopTag,
    T.TagCount
FROM 
    UserStats U
LEFT JOIN 
    PopularTags T ON T.TagName = (
        SELECT TOP 1 TagName FROM PopularTags ORDER BY TagCount DESC
    )
JOIN 
    TopUsers TU ON U.UserId = TU.UserId
WHERE 
    U.Reputation > 100
ORDER BY 
    U.TotalPosts DESC, U.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
