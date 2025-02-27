WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 2) AS AnswerCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 100 AND U.CreationDate < NOW() - INTERVAL '1 year'
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
PostActivity AS (
    SELECT 
        P.OwnerUserId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        P.TagCount,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS EditHistoryCount
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6)  -- Title, Body, Tags edits
    GROUP BY P.OwnerUserId, P.Title, P.CreationDate, P.TagCount
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM Posts P
    WHERE P.ViewCount > 1000
),
FinalOutput AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        PS.PostId,
        PS.Title AS PostTitle,
        PST.TagCount,
        U.UpvoteCount,
        U.DownvoteCount,
        U.BadgeCount,
        U.QuestionCount,
        U.AnswerCount,
        PA.CommentCount,
        PS.Score
    FROM UserStats U
    JOIN PostActivity PA ON U.UserId = PA.OwnerUserId
    LEFT JOIN PopularPosts PS ON U.UserId = PS.OwnerUserId AND PS.Rank <= 10
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostId,
    PostTitle,
    TagCount,
    UpvoteCount,
    DownvoteCount,
    BadgeCount,
    QuestionCount,
    AnswerCount,
    CommentCount,
    Score
FROM FinalOutput
WHERE UpvoteCount > DownvoteCount
AND TagCount > 2
ORDER BY Reputation DESC, UpvoteCount DESC;
