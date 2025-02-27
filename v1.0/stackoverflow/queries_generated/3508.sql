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
        U.Id
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
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
    PopularTags T ON T.TagName IN (SELECT TagName FROM PopularTags ORDER BY TagCount DESC LIMIT 1)
JOIN 
    TopUsers TU ON U.UserId = TU.UserId
WHERE 
    U.Reputation > 100
ORDER BY 
    U.TotalPosts DESC, U.Reputation DESC
FETCH FIRST 20 ROWS ONLY;
