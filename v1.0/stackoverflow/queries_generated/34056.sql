WITH RECURSIVE UserReputation AS (
    SELECT U.Id, U.Reputation, 0 AS Level
    FROM Users U
    WHERE U.Reputation > 1000
    UNION ALL
    SELECT U.Id, U.Reputation, UR.Level + 1
    FROM Users U
    JOIN UserReputation UR ON U.Reputation > 1000 * (UR.Level + 1)
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(COUNT(C.ID), 0) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    GROUP BY P.Id
),
UserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score ELSE 0 END) AS TotalQuestionScore,
        SUM(CASE WHEN P.PostTypeId = 2 THEN P.Score ELSE 0 END) AS TotalAnswerScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
)
SELECT 
    UR.Id AS UserId,
    UR.Reputation,
    UP.DisplayName,
    UP.PostsCount,
    UP.TotalViews,
    UP.QuestionsCount,
    UP.AnswersCount,
    UP.TotalQuestionScore,
    UP.TotalAnswerScore,
    PM.PostId,
    PM.Title AS PostTitle,
    PM.CreationDate AS PostCreationDate,
    PM.ViewCount AS PostViewCount,
    PM.CommentCount AS PostCommentCount,
    PM.TotalBounty
FROM UserReputation UR
JOIN UserPosts UP ON UR.Id = UP.UserId
LEFT JOIN PostMetrics PM ON UP.UserId = PM.PostId
WHERE UR.Level <= 3 -- Only top users with 3 or fewer levels of reputation
ORDER BY UR.Reputation DESC, UP.TotalViews DESC;
