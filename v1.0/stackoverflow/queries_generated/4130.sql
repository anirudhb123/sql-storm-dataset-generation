WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 -- BountyStart
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.PostCount,
        UA.TotalBounties,
        UA.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY UA.Reputation DESC, UA.PostCount DESC) AS UserRank
    FROM UserActivity UA
)
SELECT 
    RU.DisplayName,
    RU.Reputation,
    RU.PostCount,
    RU.TotalBounties,
    RU.BadgeCount,
    DATE_TRUNC('month', RU.LastPostDate) AS LastActiveMonth,
    CASE 
        WHEN RU.TotalBounties > 100 THEN 'High Bounty User'
        WHEN RU.TotalBounties BETWEEN 50 AND 100 THEN 'Moderate Bounty User'
        ELSE 'Low Bounty User'
    END AS BountyUserType,
    CASE 
        WHEN RU.BadgeCount IS NULL THEN 'No Badges'
        ELSE 'Badges Earned'
    END AS BadgeStatus
FROM RankedUsers RU
WHERE RU.UserRank <= 10

UNION ALL

SELECT 
    'Average' AS DisplayName,
    AVG(UA.Reputation) AS Reputation,
    AVG(UA.PostCount) AS PostCount,
    AVG(UA.TotalBounties) AS TotalBounties,
    AVG(UA.BadgeCount) AS BadgeCount,
    'N/A' AS LastActiveMonth,
    'N/A' AS BountyUserType,
    'N/A' AS BadgeStatus
FROM UserActivity UA
WHERE UA.Reputation > 1000;

-- This query retrieves the top 10 users based on reputation and post count, along with their bounty information,
-- while also providing a summary of average statistics for all qualifying users.
