WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostHistoryStats AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS TotalEdits,
        COUNT(DISTINCT PH.PostId) AS UniquePostsEdited,
        STRING_AGG(DISTINCT P.Title, ', ') AS EditedPostTitles,
        MIN(PH.CreationDate) AS FirstEditDate,
        MAX(PH.CreationDate) AS LastEditDate
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) -- Only title, body, and tag edits
    GROUP BY PH.UserId
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalComments,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        RANK() OVER (ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.Score
),
Engagements AS (
    SELECT 
        U.DisplayName,
        PS.TotalQuestions,
        PS.TotalAnswers,
        P.Title AS PostTitle,
        PA.TotalComments,
        PA.TotalUpvotes,
        PA.TotalDownvotes,
        PH.FirstEditDate,
        PH.LastEditDate,
        CASE 
            WHEN PS.TotalQuestions = 0 THEN NULL
            ELSE ROUND((CAST(PS.TotalAnswers AS FLOAT) / PS.TotalQuestions) * 100, 2)
        END AS AnswerToQuestionRatio
    FROM UserStats PS
    JOIN PostHistoryStats PH ON PH.UserId = PS.UserId
    JOIN PostAnalytics PA ON PA.PostId = (SELECT Id FROM Posts ORDER BY CreationDate DESC LIMIT 1) -- Most recent post for simplicity
    JOIN Users U ON U.Id = PS.UserId
    WHERE PS.Reputation >= 100
),
FinalResults AS (
    SELECT 
        E.DisplayName,
        E.TotalQuestions,
        E.TotalAnswers,
        E.PostTitle,
        E.TotalComments,
        E.TotalUpvotes,
        E.TotalDownvotes,
        E.FirstEditDate,
        E.LastEditDate,
        E.AnswerToQuestionRatio
    FROM Engagements E
    WHERE E.AnswerToQuestionRatio IS NOT NULL
    ORDER BY E.TotalUpvotes DESC
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY F.TotalUpvotes DESC) AS Rank,
    F.DisplayName,
    F.TotalQuestions,
    F.TotalAnswers,
    F.PostTitle,
    F.TotalComments,
    F.TotalUpvotes,
    F.TotalDownvotes,
    F.FirstEditDate,
    F.LastEditDate,
    F.AnswerToQuestionRatio
FROM FinalResults F
WHERE F.TotalAnswers > 0
AND F.TotalUpvotes > F.TotalDownvotes
AND F.LastEditDate >= NOW() - INTERVAL '30 days'
LIMIT 10;
