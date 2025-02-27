
WITH UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        Users.Reputation,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    GROUP BY Users.Id, Users.Reputation
), UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        GROUP_CONCAT(Name SEPARATOR ', ') AS BadgeNames
    FROM Badges
    GROUP BY UserId
), TopAnsweredQuestions AS (
    SELECT 
        Posts.Id AS QuestionId,
        Posts.Title,
        COUNT(Posts.AnswerCount) AS TotalAnswers,
        @row_number := @row_number + 1 AS Rank
    FROM Posts, (SELECT @row_number := 0) AS rn
    WHERE Posts.PostTypeId = 1
    GROUP BY Posts.Id, Posts.Title
    ORDER BY COUNT(Posts.AnswerCount) DESC
)
SELECT 
    u.UserId,
    u.Reputation,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(taq.TotalAnswers, 0) AS TotalAnswersForTopQuestion,
    COALESCE(taq.Title, 'None') AS TopQuestionTitle,
    CASE 
        WHEN u.PostCount > 10 AND u.Reputation > 1000 THEN 'Active Contributor' 
        ELSE 'Newbie' 
    END AS UserStatus
FROM UserReputation u
LEFT JOIN UserBadges ub ON u.UserId = ub.UserId
LEFT JOIN TopAnsweredQuestions taq ON taq.Rank = 1
WHERE u.Reputation IS NOT NULL
ORDER BY u.Reputation DESC
LIMIT 10 OFFSET 5;
