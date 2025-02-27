WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        COALESCE(B.BadgeCount, 0) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS BadgeCount
        FROM Badges
        GROUP BY UserId
    ) B ON U.Id = B.UserId
),
PostStats AS (
    SELECT 
        P.OwnerUserId, 
        COUNT(P.Id) AS PostCount, 
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        US.DisplayName, 
        US.Reputation, 
        PS.PostCount, 
        PS.TotalScore, 
        PS.AvgViewCount,
        RANK() OVER (ORDER BY PS.TotalScore DESC) AS ScoreRank
    FROM UserStats US
    JOIN PostStats PS ON US.UserId = PS.OwnerUserId
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.TotalScore,
    TU.AvgViewCount,
    CASE 
        WHEN TU.ScoreRank <= 10 THEN 'Top Contributor'
        WHEN TU.ScoreRank <= 50 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributionLevel
FROM TopUsers TU
WHERE TU.Reputation > (SELECT AVG(Reputation) FROM Users) OR
      (TU.PostCount > 5 AND TU.TotalScore > 20)
ORDER BY TU.TotalScore DESC
LIMIT 20;

EXCEPT 

SELECT 
    U.DisplayName,
    U.Reputation,
    PS.PostCount,
    PS.TotalScore,
    PS.AvgViewCount
FROM Users U
JOIN PostStats PS ON U.Id = PS.OwnerUserId
WHERE U.EmailHash IS NOT NULL;

WITH RECURSIVE RelatedPosts AS (
    SELECT 
        PL.PostId, 
        PL.RelatedPostId,
        1 AS Depth
    FROM PostLinks PL
    WHERE PL.PostId IN (SELECT Id FROM Posts WHERE ViewCount > 1000)

    UNION ALL

    SELECT 
        PL.PostId, 
        PL.RelatedPostId,
        RP.Depth + 1
    FROM PostLinks PL
    INNER JOIN RelatedPosts RP ON PL.PostId = RP.RelatedPostId
)
SELECT 
    RP.PostId,
    COUNT(RP.RelatedPostId) AS RelatedCount,
    MAX(RP.Depth) AS MaxDepth
FROM RelatedPosts RP
GROUP BY RP.PostId
HAVING COUNT(RP.RelatedPostId) > 2
ORDER BY MaxDepth DESC
LIMIT 10;
