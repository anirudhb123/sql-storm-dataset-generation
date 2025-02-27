
WITH TagCounts AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '>') AS Tag
    WHERE PostTypeId = 1 
    GROUP BY value
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM TagCounts
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        AVG(U.Reputation) AS AvgReputation
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
UserTopTags AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        TT.TagName,
        TT.PostCount
    FROM UserStats U
    JOIN Posts P ON U.UserId = P.OwnerUserId
    JOIN TagCounts TC ON TC.TagName IN (SELECT value FROM STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags) - 2), '>'))
    JOIN TopTags TT ON TC.TagName = TT.TagName
    WHERE U.TotalPosts > 0
),
FinalResult AS (
    SELECT 
        U.DisplayName,
        U.TotalPosts,
        U.Questions,
        U.Answers,
        U.Wikis,
        U.AvgReputation,
        STRING_AGG(DISTINCT UTT.TagName, ',') AS TopTags
    FROM UserStats U
    LEFT JOIN UserTopTags UTT ON U.UserId = UTT.UserId
    GROUP BY U.UserId, U.DisplayName, U.TotalPosts, U.Questions, U.Answers, U.Wikis, U.AvgReputation
)
SELECT 
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    Wikis,
    AvgReputation,
    TopTags
FROM FinalResult
ORDER BY TotalPosts DESC, AvgReputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
