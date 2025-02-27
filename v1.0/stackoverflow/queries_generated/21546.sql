WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
),
UserReputationStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(UP.PostCount, 0) AS PostCount,
        COALESCE(UP.QuestionCount, 0) AS QuestionCount,
        COALESCE(UP.AnswerCount, 0) AS AnswerCount,
        CASE 
            WHEN COALESCE(UP.PostCount, 0) > 0 THEN 
                ROUND((U.Reputation::decimal / COALESCE(UP.PostCount, 1)), 2) 
            ELSE 
                NULL 
        END AS ReputationPerPost
    FROM Users U
    LEFT JOIN UserPostCounts UP ON U.Id = UP.UserId
),
ClosedPosts AS (
    SELECT 
        Ph.PostId,
        Ph.CreationDate AS ClosedDate,
        ROW_NUMBER() OVER (PARTITION BY Ph.PostId ORDER BY Ph.CreationDate DESC) AS RecentClosure
    FROM PostHistory Ph
    WHERE Ph.PostHistoryTypeId IN (10, 11)
),
BadgesSummary AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeList
    FROM Badges B
    GROUP BY B.UserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(B.BadgeList, 'No Badges') AS BadgeList,
        UR.Reputation,
        UR.ReputationPerPost,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CP.PostId) FILTER (WHERE CP.RecentClosure = 1) AS RecentlyClosedPosts
    FROM Users U
    LEFT JOIN UserReputationStatistics UR ON U.Id = UR.UserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN ClosedPosts CP ON P.Id = CP.PostId
    LEFT JOIN BadgesSummary B ON U.Id = B.UserId
    GROUP BY U.Id, B.BadgeList, UR.Reputation, UR.ReputationPerPost
)
SELECT 
    UA.UserId,
    UA.Reputation,
    UA.ReputationPerPost,
    UA.BadgeList,
    UA.CommentCount,
    UA.TotalPosts,
    UA.RecentlyClosedPosts,
    CASE 
        WHEN UA.Reputation > 1000 THEN 'High Reputation'
        WHEN UA.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM UserActivity UA
WHERE UA.CommentCount > 10 OR UA.TotalPosts > 5
ORDER BY UA.Reputation DESC NULLS LAST, UA.UserId;

WITH RECURSIVE PostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        1 AS Level
    FROM Posts P
    WHERE P.ParentId IS NULL

    UNION ALL
    
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        PH.Level + 1
    FROM Posts P
    JOIN PostHierarchy PH ON P.ParentId = PH.PostId
)
SELECT 
    PH.PostId,
    PH.Title,
    PH.Level,
    COUNT(DISTINCT C.Id) AS CommentCount,
    COALESCE(AVG(C.Score), 0) AS AvgCommentScore
FROM PostHierarchy PH
LEFT JOIN Comments C ON PH.PostId = C.PostId
GROUP BY PH.PostId, PH.Title, PH.Level
HAVING PH.Level <= 5
ORDER BY PH.Level, AvgCommentScore DESC;
