
WITH UserAggregation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.CreationDate < '2023-10-01 12:34:56'
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RecentVotes AS (
    SELECT
        V.UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        COUNT(V.Id) AS TotalVotes
    FROM Votes V
    WHERE V.CreationDate > '2024-04-01 12:34:56'
    GROUP BY V.UserId
),
PostHistoryAggregation AS (
    SELECT
        PH.UserId,
        COUNT(PH.Id) AS HistoryCount,
        GROUP_CONCAT(DISTINCT PH.PostId) AS RelatedPostIds,
        MAX(PH.CreationDate) AS LastActivity
    FROM PostHistory PH
    WHERE PH.CreationDate > '2023-10-01 12:34:56'
    GROUP BY PH.UserId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.PositiveScorePosts,
    UA.NegativeScorePosts,
    COALESCE(RV.UpVotesReceived, 0) AS UpVotesReceived,
    COALESCE(RV.TotalVotes, 0) AS TotalVotes,
    COALESCE(PH.HistoryCount, 0) AS PostHistoryCount,
    COALESCE(PH.LastActivity, '1970-01-01 00:00:00') AS LastPostHistoryActivity,
    CASE 
        WHEN UA.Reputation < 100 THEN 'New Contributor'
        WHEN UA.Reputation BETWEEN 100 AND 1000 THEN 'Active Contributor'
        ELSE 'Top Contributor'
    END AS ContributionLevel
FROM UserAggregation UA
LEFT JOIN RecentVotes RV ON UA.UserId = RV.UserId
LEFT JOIN PostHistoryAggregation PH ON UA.UserId = PH.UserId
WHERE UA.PostCount > 0
ORDER BY UA.Reputation DESC, UA.DisplayName
LIMIT 10;
