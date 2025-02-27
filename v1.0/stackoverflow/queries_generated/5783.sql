WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(V.VoteTypeId = 2) AS TotalUpVotes, 
        SUM(V.VoteTypeId = 3) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON V.UserId = U.Id
    GROUP BY U.Id
),
PostHistoryCounts AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS TotalEdits,
        COUNT(DISTINCT PH.PostId) AS EditedPosts
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY PH.UserId
),
UserMetrics AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.TotalComments,
        UA.TotalBadges,
        UA.TotalScore,
        UA.TotalUpVotes,
        UA.TotalDownVotes,
        COALESCE(PHC.TotalEdits, 0) AS TotalEdits,
        COALESCE(PHC.EditedPosts, 0) AS EditedPosts
    FROM UserActivity UA
    LEFT JOIN PostHistoryCounts PHC ON UA.UserId = PHC.UserId
)
SELECT 
    UM.DisplayName,
    UM.TotalPosts,
    UM.TotalComments,
    UM.TotalBadges,
    UM.TotalScore,
    UM.TotalUpVotes,
    UM.TotalDownVotes,
    UM.TotalEdits,
    UM.EditedPosts,
    RANK() OVER (ORDER BY UM.TotalScore DESC) AS ScoreRank
FROM UserMetrics UM
WHERE UM.TotalPosts > 10
ORDER BY ScoreRank, UM.DisplayName;
