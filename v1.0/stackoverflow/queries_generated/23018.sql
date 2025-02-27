WITH RankedUsers AS (
    SELECT 
        U.Id, 
        U.Reputation, 
        U.Likes,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN U.Reputation < 100 THEN 'Newbie' 
                                             WHEN U.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate' 
                                             ELSE 'Veteran' END 
                           ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    WHERE U.Reputation IS NOT NULL
),
AnsweredQuestions AS (
    SELECT 
        P.Id AS QuestionId,
        COUNT(A.Id) AS AnswerCount, 
        MAX(A.CreationDate) AS LastAnswerDate
    FROM Posts P
    LEFT JOIN Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    WHERE P.PostTypeId = 1
    GROUP BY P.Id
),
ClosedQuestions AS (
    SELECT 
        PH.PostId, 
        MAX(PH.CreationDate) AS LastClosedDate,
        string_agg(DISTINCT C.Name, ', ') AS CloseReasons
    FROM PostHistory PH
    INNER JOIN CloseReasonTypes C ON PH.Comment = C.Id::varchar
    WHERE PH.PostHistoryTypeId IN (10, 11) /* Closed and Reopened reasons */
    GROUP BY PH.PostId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVoteTotal,
        SUM(V.VoteTypeId = 3) AS DownVoteTotal,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)

SELECT 
    U.DisplayName, 
    U.Reputation,
    COALESCE(CQ.CloseReasons, 'No closures') AS CloseReasons, 
    UR.UserRank, 
    AQ.AnswerCount AS TotalAnswers,
    UA.CommentCount, 
    UA.UpVoteTotal, 
    UA.DownVoteTotal,
    CASE 
        WHEN AQ.LastAnswerDate IS NULL THEN 'No Answers Yet'
        WHEN AQ.LastAnswerDate < (NOW() - INTERVAL '30 days') THEN 'Stale'
        ELSE 'Active'
    END AS QuestionActivityStatus
FROM Users U
LEFT JOIN AnsweredQuestions AQ ON AQ.QuestionId = (
    SELECT P.Id
    FROM Posts P
    WHERE P.OwnerUserId = U.Id AND P.PostTypeId = 1
    ORDER BY P.CreationDate DESC
    LIMIT 1
)
LEFT JOIN ClosedQuestions CQ ON CQ.PostId = AQ.QuestionId
LEFT JOIN RankedUsers UR ON UR.Id = U.Id
LEFT JOIN UserActivity UA ON UA.UserId = U.Id
WHERE UR.UserRank <= 10  /* Limit to top-ranked users */
ORDER BY U.Reputation DESC, UA.UpVoteTotal DESC
LIMIT 50;

