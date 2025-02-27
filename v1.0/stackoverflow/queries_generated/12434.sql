-- Performance Benchmarking SQL Query

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
),
PostTypesStats AS (
    SELECT 
        PT.Id AS PostTypeId,
        PT.Name AS PostType,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM PostTypes PT
    LEFT JOIN Posts P ON PT.Id = P.PostTypeId
    GROUP BY PT.Id
)

SELECT 
    US.UserId,
    US.DisplayName,
    US.BadgeCount,
    US.TotalBounty,
    US.UpVotes,
    US.DownVotes,
    US.TotalViews AS UserTotalViews,
    US.TotalScore AS UserTotalScore,
    US.TotalPosts AS UserTotalPosts,
    PTS.PostTypeId,
    PTS.PostType,
    PTS.PostCount,
    PTS.TotalViews AS PostTypeTotalViews,
    PTS.TotalScore AS PostTypeTotalScore
FROM UserStats US
JOIN PostTypesStats PTS ON US.TotalPosts > 0
ORDER BY UserTotalScore DESC, UserTotalViews DESC;
