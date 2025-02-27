WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS PostRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(COUNT(C.ID), 0) AS CommentCount,
        STUFF((SELECT ', ' + T.TagName 
               FROM Tags T 
               WHERE P.Id IN (SELECT PostId FROM Posts WHERE Tags LIKE '%' + T.TagName + '%')
               FOR XML PATH('')), 1, 2, '') AS Tags,
        CASE 
            WHEN P.AnswerCount > 0 THEN 'Answered'
            ELSE 'Unanswered'
        END AS PostStatus
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.AnswerCount
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation AS UserReputation,
    U.UpVotes, 
    U.DownVotes,
    PS.PostId, 
    PS.Title AS PostTitle,
    PS.CreationDate AS PostCreationDate,
    PS.Score AS PostScore,
    PS.CommentCount,
    PS.Tags,
    PS.PostStatus
FROM UserStats U
INNER JOIN PostDetails PS ON U.PostCount > 0
WHERE U.Reputation BETWEEN 1000 AND 5000
ORDER BY U.PostRank, PS.Score DESC
LIMIT 10;

-- Check for NULL logic and filtering out users with no activity
SELECT 
    U.DisplayName AS UserName,
    ISNULL(UP.UpVotes, 0) AS UpVotes, 
    ISNULL(DN.DownVotes, 0) AS DownVotes,
    PS.PostId, 
    PS.Title AS PostTitle,
    PS.PostStatus
FROM Users U
LEFT JOIN (
    SELECT UserId, COUNT(*) AS UpVotes 
    FROM Votes WHERE VoteTypeId = 2 GROUP BY UserId
) UP ON U.Id = UP.UserId
LEFT JOIN (
    SELECT UserId, COUNT(*) AS DownVotes 
    FROM Votes WHERE VoteTypeId = 3 GROUP BY UserId
) DN ON U.Id = DN.UserId
INNER JOIN PostDetails PS ON PS.PostId IS NOT NULL
WHERE U.LastAccessDate >= CURRENT_DATE - INTERVAL '1 YEAR'
  AND U.Reputation IS NOT NULL
ORDER BY U.DisplayName;
