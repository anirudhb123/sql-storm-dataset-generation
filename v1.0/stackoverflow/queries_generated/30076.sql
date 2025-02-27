WITH RECURSIVE UserReputationCTE AS (
    SELECT Id, Reputation, CreationDate, DisplayName,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostStats AS (
    SELECT p.Id AS PostId, p.Title, p.OwnerUserId, p.PostTypeId,
           COUNT(DISTINCT c.Id) AS CommentCount,
           COUNT(DISTINCT a.Id) AS AnswerCount,
           SUM(vb.VoteTypeId = 2) AS Upvotes, -- Sum of Upvotes
           SUM(vb.VoteTypeId = 3) AS Downvotes, -- Sum of Downvotes
           p.CreationDate,
           CASE
               WHEN p.AcceptedAnswerId IS NOT NULL THEN 1
               ELSE 0
           END AS HasAcceptedAnswer
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 -- Join with Answers
    LEFT JOIN Votes vb ON p.Id = vb.PostId
    WHERE p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts from the last year
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.PostTypeId, p.CreationDate
),
BadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
UserPosts AS (
    SELECT u.DisplayName, 
           COALESCE(ps.CommentCount, 0) AS TotalComments,
           COALESCE(ps.AnswerCount, 0) AS TotalAnswers,
           COALESCE(bc.BadgeCount, 0) AS TotalBadges,
           COALESCE(SUM(ps.Upvotes - ps.Downvotes), 0) AS VoteDifferential,
           u.Reputation
    FROM Users u
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN BadgeCounts bc ON u.Id = bc.UserId
    GROUP BY u.Id, u.DisplayName, ps.CommentCount, ps.AnswerCount, bc.BadgeCount, u.Reputation
)
SELECT r.DisplayName, 
       r.Reputation, 
       u.TotalComments, 
       u.TotalAnswers, 
       u.TotalBadges, 
       u.VoteDifferential,
       CASE 
           WHEN u.TotalBadges >= 10 THEN 'Expert' 
           WHEN u.TotalBadges >= 5 THEN 'Intermediate' 
           ELSE 'Novice' 
       END AS UserLevel,
       RANK() OVER (ORDER BY u.VoteDifferential DESC) AS VoteRank
FROM UserReputationCTE r
JOIN UserPosts u ON r.Id = u.DisplayName
WHERE r.Reputation > 100 -- Filter for high reputation users
ORDER BY u.TotalComments DESC, UserRank ASC
OPTION (MAXRECURSION 100)

