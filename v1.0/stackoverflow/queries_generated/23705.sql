WITH UserReputation AS (
    SELECT Id, Reputation, COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId, 
        P.OwnerUserId, 
        P.PostTypeId,
        P.Score,
        P.ViewCount,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY P.Id, P.OwnerUserId, P.PostTypeId, P.Score, P.ViewCount, P.Title
),
UserActivity AS (
    SELECT 
        UR.Id AS UserId,
        UR.Reputation,
        UR.BadgeCount,
        AP.PostId,
        AP.PostTypeId,
        AP.Score,
        AP.ViewCount,
        AP.UpVoteCount,
        AP.DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY AP.OwnerUserId ORDER BY AP.Score DESC) AS RN
    FROM UserReputation UR
    JOIN ActivePosts AP ON UR.Id = AP.OwnerUserId
)
SELECT 
    UA.UserId,
    UA.Reputation,
    UA.BadgeCount,
    UA.PostId,
    UA.Score,
    UA.ViewCount,
    UA.UpVoteCount,
    UA.DownVoteCount,
    CASE 
        WHEN UA.RN = 1 THEN 'Top Post'
        ELSE 'Other Post'
    END AS PostRank,
    COALESCE((
        SELECT STRING_AGG(DISTINCT T.TagName, ', ')
        FROM Tags T
        JOIN Posts P ON T.Id = P.Id
        WHERE P.Id = UA.PostId
    ), 'No Tags') AS TagsList
FROM UserActivity UA
WHERE UA.Reputation > (SELECT AVG(Reputation) FROM Users) 
AND UA.UpVoteCount > UA.DownVoteCount 
ORDER BY UA.Reputation DESC, UA.Score DESC;

SELECT 
    U.DisplayName,
    PH.PostId,
    P.Title,
    PH.CreationDate AS HistoryDate,
    PH.Comment AS ClosureReason,
    PH.PostHistoryTypeId,
    CASE 
        WHEN PH.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN PH.PostHistoryTypeId = 11 THEN 'Reopened'
        ELSE 'Other Action'
    END AS ActionType
FROM PostHistory PH
JOIN Users U ON PH.UserId = U.Id
JOIN Posts P ON PH.PostId = P.Id
WHERE PH.PostHistoryTypeId IN (10, 11)
AND PH.CreationDate BETWEEN NOW() - INTERVAL '1 year' AND NOW()
ORDER BY PH.CreationDate DESC;

WITH RankedClosedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS Rank
    FROM Posts P
    WHERE P.Id IN (SELECT PostId FROM PostHistory WHERE PostHistoryTypeId = 10)
)
SELECT * FROM RankedClosedPosts
WHERE Rank <= 10;
