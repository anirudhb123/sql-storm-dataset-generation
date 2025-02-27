WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounties,
        TotalPosts,
        TotalComments,
        TotalBadges,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
)
SELECT 
    RU.DisplayName,
    RU.Reputation,
    RU.TotalBounties,
    RU.TotalPosts,
    RU.TotalComments,
    RU.TotalBadges,
    PT.Name AS PostType,
    PH.CreationDate AS HistoryDate,
    COALESCE(PH.Comment, 'N/A') AS HistoryComment
FROM RankedUsers RU
LEFT JOIN Posts P ON RU.UserId = P.OwnerUserId
LEFT JOIN PostHistory PH ON P.Id = PH.PostId
LEFT JOIN PostTypes PT ON P.PostTypeId = PT.Id
WHERE RU.TotalPosts > 0 AND RU.TotalBounties > 0
  AND PH.CreationDate = (
      SELECT MAX(History.CreationDate)
      FROM PostHistory History
      WHERE History.PostId = P.Id
  )
ORDER BY RU.Reputation DESC, RU.TotalBounties DESC
LIMIT 10;
