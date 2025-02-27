
WITH UserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalViews,
        TotalScore,
        (SELECT COUNT(*) FROM UserPosts UP2 WHERE UP2.PostCount > UP1.PostCount) + 1 AS PostRank,
        (SELECT COUNT(*) FROM UserPosts UP2 WHERE UP2.TotalViews > UP1.TotalViews) + 1 AS ViewRank,
        (SELECT COUNT(*) FROM UserPosts UP2 WHERE UP2.TotalScore > UP1.TotalScore) + 1 AS ScoreRank
    FROM 
        UserPosts UP1
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalViews,
    TotalScore,
    PostRank,
    ViewRank,
    ScoreRank
FROM 
    TopUsers
WHERE 
    PostCount > 0
ORDER BY 
    PostCount DESC, TotalViews DESC, TotalScore DESC;
