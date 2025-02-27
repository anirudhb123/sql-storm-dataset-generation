WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.Views,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS UserRank
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.Reputation, U.Views
), PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        COALESCE(PT.Name, 'Unknown') AS PostType,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Accepted' 
            ELSE 'Pending' 
        END AS AnswerStatus,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    LEFT JOIN PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, PT.Name, P.CreationDate, P.ViewCount, P.Score, P.AnswerCount, P.CommentCount, P.AcceptedAnswerId
), RankedPosts AS (
    SELECT 
        PM.PostId,
        PM.Title,
        PM.CreationDate,
        PM.ViewCount,
        PM.Score,
        PM.AnswerCount,
        PM.CommentCount,
        PM.PostType,
        PM.AnswerStatus,
        UP.UserId,
        UP.Reputation,
        UP.Views,
        UP.UpVotes,
        UP.DownVotes,
        UP.UserRank
    FROM PostMetrics PM
    JOIN UserStatistics UP ON PM.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = UP.UserId)
    WHERE UP.Reputation > 1000 OR PM.Score > 5
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.AnswerCount,
    RP.CommentCount,
    RP.PostType,
    RP.AnswerStatus,
    RP.Reputation,
    RP.UpVotes,
    RP.DownVotes,
    CASE 
        WHEN RP.UserRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory,
    COALESCE(STRING_AGG(DISTINCT T.TagName, ', '), 'No Tags') AS RelatedTags
FROM RankedPosts RP
LEFT JOIN Posts P ON RP.PostId = P.Id
LEFT JOIN Tags T ON POSITION(CONCAT('<', T.TagName, '>') IN P.Tags) > 0
WHERE RP.ViewCount > 50
GROUP BY RP.PostId, RP.Title, RP.CreationDate, RP.ViewCount, RP.Score, RP.AnswerCount, RP.CommentCount, RP.PostType, RP.AnswerStatus, RP.Reputation, RP.UpVotes, RP.DownVotes, RP.UserRank
ORDER BY RP.CreationDate DESC, RP.Score DESC
LIMIT 100;
