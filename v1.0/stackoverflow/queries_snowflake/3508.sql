
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
        TRIM(SPLIT_PART(Tags, '><', seq.seq)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT ROW_NUMBER() OVER() AS seq FROM TABLE(GENERATOR(ROWCOUNT => 100))) seq
    ON
        seq.seq <= ARRAY_SIZE(SPLIT(Tags, '><'))
    WHERE 
        Posts.PostTypeId = 1
    GROUP BY 
        TRIM(SPLIT_PART(Tags, '><', seq.seq))
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
    (SELECT TagName, TagCount FROM PopularTags ORDER BY TagCount DESC LIMIT 1) T ON T.TagName IS NOT NULL
JOIN 
    TopUsers TU ON U.UserId = TU.UserId
WHERE 
    U.Reputation > 100
ORDER BY 
    U.TotalPosts DESC, U.Reputation DESC
LIMIT 20;
