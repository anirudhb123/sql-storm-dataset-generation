WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagList
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN PostsTags PT ON P.Id = PT.PostId
    LEFT JOIN Tags T ON PT.TagId = T.Id
    WHERE U.Reputation IS NOT NULL 
        AND U.CreationDate < NOW() - INTERVAL '1 year'
    GROUP BY U.Id
),

PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Socre,
        PH.CreationDate AS HistoryDate,
        PH.UserDisplayName AS Editor,
        PH.Comment,
        PH.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS EditRank
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '1 month'
)

SELECT 
    US.DisplayName AS UserName,
    US.Reputation,
    US.PostCount,
    US.CommentCount,
    US.UpVotes,
    US.DownVotes,
    US.TagList,
    PD.PostId,
    PD.Title,
    PD.CreationDate AS PostCreationDate,
    PD.Score,
    PD.HistoryDate,
    PD.Editor AS LastEditor,
    PD.Comment AS LastEditComment,
    PD.PostHistoryTypeId,
    CASE WHEN PD.EditRank = 1 THEN 'Latest Edit' ELSE 'Earlier Edit' END AS EditStatus
FROM UserStats US
JOIN PostDetails PD ON US.UserId = PD.OwnerUserId
WHERE US.PostCount > 0 
AND (US.Reputation >= 1000 OR US.CommentCount > 5)
ORDER BY US.Reputation DESC, PD.Score DESC, PD.HistoryDate DESC
LIMIT 100;

-- To handle NULL logic intricacies:
-- Suppose we want to also include those users with a null reputation or creation date within the filtering criteria:
UNION ALL 
SELECT 
    U.DisplayName,
    COALESCE(U.Reputation, 0) AS Reputation,
    COALESCE(UP.PostCount, 0) AS PostCount,
    COALESCE(UC.CommentCount, 0) AS CommentCount,
    0 AS UpVotes,
    0 AS DownVotes,
    NULL AS TagList,
    0 AS PostId, 
    'No Posts' AS Title,
    NULL AS PostCreationDate,
    0 AS Score,
    NULL AS HistoryDate,
    NULL AS LastEditor,
    NULL AS LastEditComment,
    NULL AS PostHistoryTypeId,
    NULL AS EditStatus
FROM Users U
LEFT JOIN (SELECT UserId, COUNT(*) AS PostCount FROM Posts GROUP BY UserId) UP ON U.Id = UP.UserId
LEFT JOIN (SELECT UserId, COUNT(*) AS CommentCount FROM Comments GROUP BY UserId) UC ON U.Id = UC.UserId
WHERE U.Reputation IS NULL OR U.CreationDate IS NULL
ORDER BY Reputation DESC
LIMIT 100;
