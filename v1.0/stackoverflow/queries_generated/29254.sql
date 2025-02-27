WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePostCount,
        SUM(V.BountyAmount) AS TotalBounty,
        AVG(U.Reputation) AS AverageReputation,
        MAX(U.LastAccessDate) AS LastActive
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastEditDate,
        PT.Name AS PostType,
        COUNT(PH.Id) AS HistoryCount,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS ViralCount,
        STUFF((SELECT ', ' + T.TagName
               FROM Tags T
               WHERE P.Tags LIKE '%' + T.TagName + '%'
               FOR XML PATH('')), 1, 2, '') AS TagsList
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.LastEditDate, PT.Name
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.TotalComments,
        UA.PositivePostCount,
        UA.NegativePostCount,
        UA.TotalBounty,
        UA.AverageReputation,
        ROW_NUMBER() OVER (ORDER BY UA.TotalPosts DESC) AS Rank
    FROM UserActivity UA
    WHERE UA.TotalPosts > 10
),
PopularPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.ViewCount,
        PS.ViralCount,
        PS.TagsList,
        ROW_NUMBER() OVER (ORDER BY PS.ViewCount DESC) AS PopularityRank
    FROM PostStatistics PS
    WHERE PS.ViralCount > 3
)
SELECT 
    TU.Rank AS UserRank,
    TU.DisplayName AS ActiveUser,
    TU.TotalPosts,
    TU.TotalComments,
    TU.PositivePostCount,
    TU.NegativePostCount,
    TU.TotalBounty,
    TU.AverageReputation,
    PP.Title AS PopularPostTitle,
    PP.ViewCount AS PostViews,
    PP.TagsList AS AssociatedTags
FROM TopUsers TU
JOIN PopularPosts PP ON TU.TotalPosts > 10
ORDER BY TU.Rank, PP.ViewCount DESC;
