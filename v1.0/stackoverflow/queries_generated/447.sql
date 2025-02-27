WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        PostCount,
        AnswerCount,
        TotalBounty,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.Views,
    TU.PostCount,
    TU.AnswerCount,
    COALESCE(B.Name, 'No Badge') AS Badge,
    CASE 
        WHEN TU.TotalBounty > 100 THEN 'High Bounty Contributor'
        ELSE 'Regular Contributor' 
    END AS ContributorType
FROM TopUsers TU
LEFT JOIN Badges B ON TU.UserId = B.UserId AND B.Class = 1
WHERE TU.Rank <= 10
ORDER BY TU.Rank;

WITH RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS ChangesCount
    FROM PostHistory PH
    WHERE PH.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY PH.PostId, PH.PostHistoryTypeId
),
PostWithRecentHistory AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(RCH.ChangesCount, 0) AS RecentChanges
    FROM Posts P
    LEFT JOIN RecentPostHistory RCH ON P.Id = RCH.PostId
    WHERE P.CreationDate > NOW() - INTERVAL '365 days' 
)
SELECT 
    PU.DisplayName,
    PWR.Title,
    PWR.RecentChanges,
    CASE 
        WHEN PWR.RecentChanges > 5 THEN 'High Activity'
        ELSE 'Moderate Activity' 
    END AS ActivityLevel
FROM PostWithRecentHistory PWR
JOIN Users PU ON PU.Id = PWR.OwnerUserId
ORDER BY PWR.RecentChanges DESC;
