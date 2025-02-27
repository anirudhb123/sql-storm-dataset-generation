WITH RecursivePostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.OwnerUserId,
        1 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1  -- Only questions
    UNION ALL
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.OwnerUserId,
        Level + 1
    FROM Posts P
    INNER JOIN RecursivePostStats R ON P.ParentId = R.PostId
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
),
TopUsers AS (
    SELECT UserId, DisplayName, Reputation
    FROM UserReputation
    WHERE Rank <= 10
),
PostHistoryCounts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS EditCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 24) -- Edit Title, Edit Body, Suggested Edit Applied
    GROUP BY PH.PostId
)
SELECT 
    R.Title,
    U.DisplayName AS Owner,
    COALESCE(E.EditCount, 0) AS TotalEdits,
    R.Score,
    R.ViewCount,
    R.AnswerCount,
    R.CreationDate,
    CASE 
        WHEN R.Score > 100 THEN 'High Quality'
        WHEN R.Score BETWEEN 51 AND 100 THEN 'Medium Quality'
        ELSE 'Low Quality'
    END AS Quality,
    STRING_AGG(T.TagName, ', ') AS Tags
FROM RecursivePostStats R
LEFT JOIN Users U ON R.OwnerUserId = U.Id
LEFT JOIN PostHistoryCounts E ON R.PostId = E.PostId
LEFT JOIN Posts P ON R.PostId = P.Id
LEFT JOIN LATERAL (
    SELECT 
        T.TagName
    FROM Tags T
    WHERE T.Id IN (
        SELECT UNNEST(string_to_array(P.Tags, '<>'))::int
    )
) AS T ON TRUE
WHERE R.Level = 1 -- only top-level questions
AND U.Reputation > 1000 -- filter out users with low reputation
GROUP BY R.Title, U.DisplayName, E.EditCount, R.Score, R.ViewCount, R.AnswerCount, R.CreationDate
ORDER BY R.Score DESC, R.ViewCount DESC;
