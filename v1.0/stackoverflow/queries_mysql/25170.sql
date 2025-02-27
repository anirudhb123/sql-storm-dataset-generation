
WITH TagStats AS (
    SELECT
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        GROUP_CONCAT(DISTINCT U.DisplayName ORDER BY U.DisplayName SEPARATOR ', ') AS ContributingUsers
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    WHERE T.Count > 50 
    GROUP BY T.TagName
),
UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM Users U
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopTags AS (
    SELECT
        TS.TagName,
        TS.PostCount,
        TS.TotalViews,
        TS.AverageScore,
        TS.ContributingUsers,
        @tagRank := @tagRank + 1 AS TagRank
    FROM TagStats TS, (SELECT @tagRank := 0) r
    ORDER BY TS.TotalViews DESC
),
TopUsers AS (
    SELECT
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        UR.PostCount,
        UR.TotalViews,
        @userRank := @userRank + 1 AS UserRank
    FROM UserReputation UR, (SELECT @userRank := 0) r
    ORDER BY UR.Reputation DESC
)
SELECT
    T.TagName,
    T.PostCount,
    T.TotalViews,
    T.AverageScore,
    T.ContributingUsers,
    U.DisplayName AS TopUser,
    U.Reputation AS UserReputation
FROM TopTags T
JOIN TopUsers U ON T.TagRank = U.UserRank
WHERE T.TagRank <= 5 AND U.UserRank <= 5
ORDER BY T.TotalViews DESC, U.Reputation DESC;
