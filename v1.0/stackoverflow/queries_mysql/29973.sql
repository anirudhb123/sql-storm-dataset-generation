
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n + 1), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    JOIN (
        SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
        UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
        UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n
    WHERE PostTypeId = 1 
    GROUP BY TagName
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
        TC.TagName,
        TC.PostCount
    FROM UserStats U
    JOIN Posts P ON U.UserId = P.OwnerUserId
    JOIN TagCounts TC ON FIND_IN_SET(TC.TagName, REPLACE(SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2), '><', ',')) > 0
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
        GROUP_CONCAT(DISTINCT UTT.TagName) AS TopTags
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
LIMIT 10;
