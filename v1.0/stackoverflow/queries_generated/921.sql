WITH UserPostMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.EmailHash,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
)
SELECT 
    TU.DisplayName,
    UPM.TotalViews,
    UPM.TotalScore,
    TU.Reputation,
    TU.ReputationRank,
    CASE 
        WHEN UPM.PostCount > 0 THEN ROUND((UPM.TotalScore::decimal / UPM.PostCount), 2)
        ELSE 0.00 
    END AS AverageScorePerPost,
    (
        SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
        FROM Posts P 
        JOIN UNNEST(string_to_array(P.Tags, '><')) AS T(TagName) ON P.Id = P.Id 
        WHERE P.OwnerUserId = UPM.UserId
    ) AS TagsUsed
FROM UserPostMetrics UPM
JOIN TopUsers TU ON UPM.UserId = TU.Id
WHERE TU.ReputationRank <= 10
ORDER BY TU.Reputation DESC 
LIMIT 5;
