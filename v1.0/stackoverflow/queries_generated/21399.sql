WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.Reputation > 0
),
PostStatistics AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
PostHistoryStats AS (
    SELECT
        PH.UserId,
        COUNT(PH.Id) AS HistoryCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount
    FROM PostHistory PH
    GROUP BY PH.UserId
),
CombinedStats AS (
    SELECT
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        PS.TotalPosts,
        PS.QuestionCount,
        PS.AnswerCount,
        PS.TotalViews,
        PS.AverageScore,
        PHS.HistoryCount,
        PHS.CloseReopenCount,
        PHS.DeleteUndeleteCount
    FROM UserReputation UR
    LEFT JOIN PostStatistics PS ON UR.UserId = PS.OwnerUserId
    LEFT JOIN PostHistoryStats PHS ON UR.UserId = PHS.UserId
)
SELECT
    C.*,
    COALESCE(P.HotPostCount, 0) AS HotPostCount,
    STRING_AGG(DISTINCT T.TagName, ', ') AS AssociatedTags
FROM CombinedStats C
LEFT JOIN (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS HotPostCount
    FROM Posts P
    WHERE P.Score > 5
    GROUP BY P.OwnerUserId
) P ON C.UserId = P.OwnerUserId
LEFT JOIN LATERAL (
    SELECT
        TRIM(REGEXP_REPLACE(P.Tags, '<[^>]*>', '', 'g')) AS TagName
    FROM Posts P
    WHERE P.OwnerUserId = C.UserId AND P.Tags IS NOT NULL
    LIMIT 5
) T ON TRUE
GROUP BY C.UserId, C.DisplayName, C.Reputation, C.TotalPosts, C.QuestionCount, C.AnswerCount, C.TotalViews, C.AverageScore, P.HotPostCount
HAVING C.ReputationRank <= 10 OR (C.HistoryCount > 5 AND C.Reputation > 100)
ORDER BY C.Reputation DESC, C.HistoryCount DESC;
