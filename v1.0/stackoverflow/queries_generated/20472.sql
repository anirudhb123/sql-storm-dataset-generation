WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
), 
PostAggregates AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        COALESCE(SUM(ViewCount), 0) AS TotalViewCount,
        COALESCE(SUM(Score), 0) AS TotalScore
    FROM Posts
    WHERE CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY OwnerUserId
),
UserStats AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        PA.PostCount,
        PA.TotalViewCount,
        PA.TotalScore,
        CASE 
            WHEN PA.PostCount > 0 THEN PA.TotalScore::decimal / PA.PostCount
            ELSE 0 
        END AS AverageScorePerPost
    FROM UserReputation UR
    LEFT JOIN PostAggregates PA ON UR.UserId = PA.OwnerUserId
    WHERE UR.Reputation > 1000
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalViewCount,
        AverageScorePerPost,
        RANK() OVER (ORDER BY TotalScore DESC) AS TotalScoreRank
    FROM UserStats
    WHERE ReputationRank <= 10  -- Filter to top 10 by rank
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.TotalViewCount,
    U.AverageScorePerPost,
    COALESCE((SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
               FROM Posts P 
               JOIN (SELECT Id, Tags 
                     FROM Posts 
                     WHERE OwnerUserId = U.UserId) AS PostTags 
               ON P.Id = PostTags.Id 
               CROSS JOIN LATERAL 
               (SELECT UNNEST(string_to_array(Tags, '><')) AS TagName) AS T 
               WHERE P.OwnerUserId = U.UserId), 
               'No Tags') AS PopularTags,
    CASE 
        WHEN U.TotalViewCount IS NULL THEN 'Unknown'
        WHEN U.TotalViewCount > 10000 THEN 'Popular'
        ELSE 'Less Popular' 
    END AS PopularityStatus
FROM TopUsers U
LEFT JOIN Badges B ON B.UserId = U.UserId
GROUP BY U.UserId, U.DisplayName, U.Reputation, U.PostCount, U.TotalViewCount, U.AverageScorePerPost
HAVING COUNT(B.Id) > 0 
ORDER BY U.TotalScoreRank, U.Reputation DESC;
