WITH RankedPosts AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.CreationDate,
           P.Body,
           P.AnswerCount,
           P.Score,
           ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM Posts P
    WHERE P.CreateDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           COUNT(DISTINCT B.Id) AS BadgeCount,
           SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostHistoryAnalysis AS (
    SELECT PH.PostId,
           COUNT(*) AS EditCount,
           ARRAY_AGG(DISTINCT PH.PostHistoryTypeId) AS EditTypes
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY PH.PostId
),
RecentClosures AS (
    SELECT P.Id AS PostId,
           PH.UserId AS CloserUserId,
           COUNT(*) AS CloseCount
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId = 10 -- Post Closed
    AND PH.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY P.Id, PH.UserId
)
SELECT RP.PostId,
       RP.Title,
       RP.CreationDate,
       RP.Body,
       RP.AnswerCount,
       RP.Score,
       US.DisplayName AS UserName,
       US.Reputation,
       US.BadgeCount,
       US.TotalBounty,
       PH.EditCount,
       COALESCE(ARRAY_TO_STRING(PH.EditTypes, ', '), 'No Edits') AS EditTypes,
       RC.ClosingUserId,
       RC.CloseCount
FROM RankedPosts RP
JOIN UserStats US ON RP.PostId = (SELECT AcceptedAnswerId FROM Posts WHERE Id = RP.PostId)
LEFT JOIN PostHistoryAnalysis PH ON RP.PostId = PH.PostId
LEFT JOIN RecentClosures RC ON RP.PostId = RC.PostId
WHERE RP.Rank <= 5
AND (COALESCE(RC.CloseCount, 0) = 0 OR US.Reputation > 1000) -- Adding bizarre logic: CloseCount must be 0 or User Reputation must be over 1000
ORDER BY RP.Score DESC, RP.CreationDate DESC
LIMIT 10;

