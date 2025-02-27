WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate,
           ROW_NUMBER() OVER (PARTITION BY Id ORDER BY CreationDate DESC) AS rn
    FROM Users
),
TopBadges AS (
    SELECT UserId, COUNT(*) AS TotalBadges
    FROM Badges
    WHERE Class = 1 OR Class = 2
    GROUP BY UserId
),
PostStats AS (
    SELECT OwnerUserId, 
           COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS TotalQuestions,
           COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS TotalAnswers,
           SUM(ViewCount) AS TotalViews,
           AVG(Score) AS AvgScore
    FROM Posts
    GROUP BY OwnerUserId
),
PopularUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation,
           COALESCE(tb.TotalBadges, 0) AS TotalBadges,
           ps.TotalQuestions, ps.TotalAnswers, ps.TotalViews, ps.AvgScore
    FROM Users u
    LEFT JOIN TopBadges tb ON u.Id = tb.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    WHERE u.Reputation > 1000
),
CommentsSummary AS (
    SELECT PostId,
           COUNT(*) AS CommentsCount,
           MAX(CreationDate) AS LastCommentDate
    FROM Comments
    GROUP BY PostId
),
FinalResult AS (
    SELECT pu.DisplayName, pu.Reputation, pu.TotalBadges,
           ps.TotalQuestions, ps.TotalAnswers, ps.TotalViews, ps.AvgScore,
           cs.CommentsCount, cs.LastCommentDate
    FROM PopularUsers pu
    LEFT JOIN CommentsSummary cs ON cs.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = pu.Id)
    ORDER BY pu.Reputation DESC
)

SELECT DisplayName, Reputation, TotalBadges,
       TotalQuestions, TotalAnswers, TotalViews, AvgScore,
       COALESCE(CommentsCount, 0) AS CommentsCount,
       COALESCE(LastCommentDate, '1970-01-01') AS LastCommentDate
FROM FinalResult;
