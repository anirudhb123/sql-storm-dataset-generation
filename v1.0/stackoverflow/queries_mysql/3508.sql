
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts JOIN
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        Posts.PostTypeId = 1
    GROUP BY 
        TagName
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
        SELECT TagName FROM PopularTags ORDER BY TagCount DESC LIMIT 1
    )
JOIN 
    TopUsers TU ON U.UserId = TU.UserId
WHERE 
    U.Reputation > 100
ORDER BY 
    U.TotalPosts DESC, U.Reputation DESC
LIMIT 20;
