WITH UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersGiven,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.Reputation > 1000 AND U.Location IS NOT NULL
    GROUP BY U.Id
),
RankedUsers AS (
    SELECT
        UserId,
        DisplayName,
        QuestionsAsked,
        AnswersGiven,
        UpVotesReceived,
        DownVotesReceived,
        RANK() OVER (ORDER BY QuestionsAsked DESC, UpVotesReceived DESC) AS ActivityRank
    FROM UserActivity
)
SELECT
    R.DisplayName,
    R.QuestionsAsked,
    R.AnswersGiven,
    R.UpVotesReceived,
    R.DownVotesReceived,
    CASE 
        WHEN R.DownVotesReceived > 0 THEN 'Negative Feedback'
        ELSE 'Positive or Neutral Feedback'
    END AS FeedbackCategory,
    CASE 
        WHEN R.QuestionsAsked > 10 THEN 'High Activity'
        WHEN R.QuestionsAsked BETWEEN 5 AND 10 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel,
    (SELECT STRING_AGG(P.Title, ', ') 
     FROM Posts P 
     WHERE P.OwnerUserId = R.UserId AND P.PostTypeId = 1 
     ORDER BY P.CreationDate DESC 
     LIMIT 5) AS RecentQuestions
FROM RankedUsers R
WHERE R.ActivityRank <= 10
ORDER BY R.UpVotesReceived DESC;
