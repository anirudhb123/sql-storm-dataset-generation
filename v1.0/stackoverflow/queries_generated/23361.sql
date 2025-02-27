WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(VoteCount, 0)) AS TotalVotes,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
TopAnsweredQuestions AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.AnswerCount,
        P.Score,
        COALESCE(P.CreatedDate, P.LastActivityDate) AS LastActivity
    FROM Posts P
    WHERE P.PostTypeId = 1 AND P.AnswerCount > 3
    ORDER BY P.Score DESC
    LIMIT 10
),
ClosedPostReasons AS (
    SELECT 
        PH.PostId,
        PH.Comment,
        PH.CreationDate,
        CRT.Name AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes CRT ON PH.Comment::int = CRT.Id
    WHERE PH.PostHistoryTypeId = 10
),
UserEngagement AS (
    SELECT 
        R.UserId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        AVG(COALESCE(Score, 0)) AS AvgCommentScore
    FROM RankedUsers R
    LEFT JOIN Comments C ON R.UserId = C.UserId
    GROUP BY R.UserId
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.TotalVotes,
    U.GoldBadges,
    QA.Title AS TopQuestion,
    QA.AnswerCount,
    QA.Score AS QuestionScore,
    CPA.CloseReason,
    UE.CommentCount AS UserCommentCount,
    UE.AvgCommentScore AS UserAvgCommentScore
FROM RankedUsers U
LEFT JOIN TopAnsweredQuestions QA ON U.PostCount > 0
LEFT JOIN ClosedPostReasons CPA ON CPA.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.UserId)
LEFT JOIN UserEngagement UE ON U.UserId = UE.UserId
WHERE U.ReputationRank <= 50
ORDER BY U.Reputation DESC, U.TotalVotes DESC, UserCommentCount DESC;

WITH UserBadgeCount AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        CASE 
            WHEN COUNT(*) > 5 THEN 'Veteran'
            ELSE 'Novice'
        END AS BadgeStatus
    FROM Badges
    GROUP BY UserId
)
SELECT 
    U.DisplayName, 
    U.Reputation, 
    U.UserRank,
    UBC.BadgeStatus
FROM Users U
LEFT JOIN UserBadgeCount UBC ON U.Id = UBC.UserId
WHERE EXISTS (
    SELECT 1 
    FROM Posts P 
    WHERE P.OwnerUserId = U.Id
    HAVING COUNT(P.Id) > 1
)
ORDER BY U.Reputation DESC;
