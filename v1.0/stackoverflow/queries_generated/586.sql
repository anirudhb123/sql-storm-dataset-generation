WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount, 
           STRING_AGG(Name, ', ') AS BadgeNames
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT OwnerUserId, 
           COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS QuestionCount,
           COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS AnswerCount,
           SUM(ViewCount) AS TotalViews,
           SUM(Score) AS TotalScore
    FROM Posts
    GROUP BY OwnerUserId
),
UserActivity AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           U.Reputation,
           COALESCE(UB.BadgeCount, 0) AS BadgeCount,
           U.LastAccessDate,
           PS.QuestionCount,
           PS.AnswerCount,
           PS.TotalViews,
           PS.TotalScore,
           ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
)

SELECT UA.UserId, UA.DisplayName, UA.Reputation,
       UA.BadgeCount, UA.LastAccessDate,
       COALESCE(UA.QuestionCount, 0) AS QuestionCount,
       COALESCE(UA.AnswerCount, 0) AS AnswerCount,
       COALESCE(UA.TotalViews, 0) AS TotalViews,
       COALESCE(UA.TotalScore, 0) AS TotalScore,
       (SELECT STRING_AGG(Name, ', ') 
        FROM PostHistory PH 
        WHERE PH.UserId = UA.UserId 
        AND PH.PostHistoryTypeId IN (10, 11, 12, 13)) AS RecentActions,
       (SELECT MAX(CreationDate) 
        FROM Comments C 
        WHERE C.UserId = UA.UserId) AS LastCommentDate,
       (SELECT COUNT(*) 
        FROM Votes V 
        WHERE V.UserId = UA.UserId 
        AND V.CreationDate >= NOW() - INTERVAL '1 year') AS RecentVotes
FROM UserActivity UA
WHERE UA.Reputation > 100
ORDER BY UA.UserRank
LIMIT 50;
