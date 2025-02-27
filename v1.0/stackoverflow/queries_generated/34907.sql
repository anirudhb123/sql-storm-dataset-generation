WITH RecursivePostCTE AS (
    -- Recursive CTE to find all ancestor posts of an answer.
    SELECT p.Id, p.Title, p.ParentId, p.OwnerUserId, 1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 2  -- Select only answers

    UNION ALL

    SELECT p.Id, p.Title, p.ParentId, p.OwnerUserId, rpc.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostCTE rpc ON p.Id = rpc.ParentId
),
UserStats AS (
    -- Aggregate user statistics including their badges.
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(DISTINCT b.Id) AS TotalBadges,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
           SUM(p.ViewCount) AS TotalViews,
           SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
PostActivity AS (
    -- Calculate post activity for each question with the number of answers and comments.
    SELECT q.Id AS QuestionId,
           COALESCE(a.AnswerCount, 0) AS AnswerCount,
           COALESCE(c.CommentCount, 0) AS CommentCount,
           q.Title
    FROM Posts q
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2  -- Answers
        GROUP BY ParentId
    ) a ON q.Id = a.ParentId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON q.Id = c.PostId
    WHERE q.PostTypeId = 1  -- Questions only
),
FinalResults AS (
    -- Combine user statistics and post activity with data from recursive post CTE.
    SELECT u.UserId,
           u.DisplayName,
           ps.QuestionId,
           ps.Title,
           ps.AnswerCount,
           ps.CommentCount,
           us.TotalBadges,
           us.GoldBadges,
           us.SilverBadges,
           us.BronzeBadges,
           us.TotalViews,
           us.TotalScore,
           rpc.Level AS AnswerLevel
    FROM UserStats us
    LEFT JOIN PostActivity ps ON us.UserId = ps.QuestionId  -- Match users to their posts
    LEFT JOIN RecursivePostCTE rpc ON ps.QuestionId = rpc.ParentId
)
-- Final selection with some complex conditions and cases 
SELECT UserId,
       DisplayName,
       QuestionId,
       Title,
       AnswerCount,
       CommentCount,
       TotalBadges,
       GoldBadges,
       SilverBadges,
       BronzeBadges,
       TotalViews,
       TotalScore,
       CASE 
           WHEN AnswerCount > 0 THEN 'Active Contributor'
           WHEN TotalScore > 1000 THEN 'Veteran'
           ELSE 'New User'
       END AS UserClassification
FROM FinalResults
WHERE TotalBadges > 0 OR AnswerCount > 0  -- Filter users with at least one badge or an answer
ORDER BY UserId, AnswerCount DESC, CommentCount DESC;
