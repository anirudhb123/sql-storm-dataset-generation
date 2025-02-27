WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        CASE 
            WHEN U.Reputation IS NULL THEN 'No Reputation'
            WHEN U.Reputation < 1000 THEN 'Newbie'
            WHEN U.Reputation < 5000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM Users U
),
QuestionAnswerInfo AS (
    SELECT 
        P.Id AS QuestionId,
        COALESCE(A.Id, -1) AS AcceptedAnswerId,
        COUNT(Ans.Id) AS TotalAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Posts P
    LEFT JOIN Posts A ON P.AcceptedAnswerId = A.Id
    LEFT JOIN Posts Ans ON P.Id = Ans.ParentId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.PostTypeId = 1
    GROUP BY P.Id, A.Id
),
ClosedQuestions AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS CloseDate,
        CT.Name AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes CT ON PH.Comment::int = CT.Id
    WHERE PH.PostHistoryTypeId = 10
),
UserVotingStatistics AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT V.PostId) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS Upvotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
FinalAnalysis AS (
    SELECT 
        U.DisplayName,
        UR.Reputation,
        QA.QuestionId,
        QA.AcceptedAnswerId,
        QA.TotalAnswers,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COALESCE(CQ.CloseDate, 'Never Closed') AS CloseDate,
        COALESCE(CQ.CloseReason, 'N/A') AS CloseReason,
        UStat.TotalVotes,
        UStat.Upvotes AS UserUpvotes,
        CASE 
            WHEN QA.TotalAnswers = 0 THEN 'No Answers'
            WHEN QA.Upvotes > QA.Downvotes THEN 'Positive'
            WHEN QA.Upvotes < QA.Downvotes THEN 'Negative'
            ELSE 'Neutral'
        END AS AnswerSentiment
    FROM UserReputation UR
    JOIN QuestionAnswerInfo QA ON UR.UserId = QA.QuestionId
    LEFT JOIN Comments C ON QA.QuestionId = C.PostId
    LEFT JOIN ClosedQuestions CQ ON QA.QuestionId = CQ.PostId
    LEFT JOIN UserVotingStatistics UStat ON UR.UserId = UStat.UserId
    GROUP BY U.DisplayName, UR.Reputation, QA.QuestionId, QA.AcceptedAnswerId, QA.TotalAnswers, CQ.CloseDate, CQ.CloseReason, UStat.TotalVotes, UStat.Upvotes
)
SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY ReputationLevel ORDER BY TotalVotes DESC) AS RankByVotes
FROM FinalAnalysis
ORDER BY Reputation DESC, TotalVotes DESC, CloseDate;
