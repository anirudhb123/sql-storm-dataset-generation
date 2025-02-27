WITH UserReputation AS (
    SELECT Id, Reputation, DisplayName
    FROM Users
    WHERE Reputation > 100
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
RecentPostActivity AS (
    SELECT 
        P.Id AS PostId,
        C.UserDisplayName AS Commenter,
        C.Text AS CommentText,
        C.CreationDate AS CommentDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate > NOW() - INTERVAL '30 days'
),
PostHistorySummary AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount,
        MAX(CreationDate) AS LastEditDate
    FROM PostHistory
    WHERE PostHistoryTypeId IN (4, 5, 6)
    GROUP BY PostId
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    PS.Questions,
    PS.Answers,
    PS.TotalScore,
    PS.TotalViews,
    COALESCE(PHS.EditCount, 0) AS TotalEdits,
    PHS.LastEditDate,
    RPA.Commenter,
    RPA.CommentText,
    RPA.CommentDate
FROM UserReputation UR
JOIN PostStats PS ON UR.Id = PS.OwnerUserId
LEFT JOIN PostHistorySummary PHS ON PHS.PostId IN (
    SELECT Id FROM Posts WHERE OwnerUserId = UR.Id
)
LEFT JOIN RecentPostActivity RPA ON RPA.PostId IN (
    SELECT Id FROM Posts WHERE OwnerUserId = UR.Id
)
WHERE UR.Reputation BETWEEN 100 AND 1000
ORDER BY UR.Reputation DESC, PS.TotalScore DESC
LIMIT 50;
