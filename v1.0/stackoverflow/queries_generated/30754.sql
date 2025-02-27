WITH RECURSIVE PopularPosts AS (
    SELECT p.Id, p.Title, p.Score, p.AnswerCount, p.ViewCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Select only questions
),
PostVotes AS (
    SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS NetVotes
    FROM Votes
    GROUP BY PostId
),
HighScoringPosts AS (
    SELECT pp.Id, pp.Title, pp.Score, pp.ViewCount, pv.NetVotes
    FROM PopularPosts pp
    JOIN PostVotes pv ON pp.Id = pv.PostId
    WHERE pp.rn = 1 -- Only take the top post for each user
),
UserBadges AS (
    SELECT u.Id AS UserId, COUNT(b.Id) AS BadgeCount,
           STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT u.DisplayName, u.Reputation, u.CreationDate, 
       COALESCE(hp.Title, 'No posts') AS PopularPostTitle,
       COALESCE(hp.Score, 0) AS PopularPostScore,
       COALESCE(hp.NetVotes, 0) AS PopularPostVotes,
       ub.BadgeCount, ub.BadgeNames
FROM Users u
LEFT JOIN HighScoringPosts hp ON u.Id = hp.OwnerUserId
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE u.Reputation > 1000 AND ub.BadgeCount IS NOT NULL
ORDER BY u.Reputation DESC, hp.Score DESC
FETCH FIRST 10 ROWS ONLY;

This query does the following:

1. **Common Table Expressions (CTEs)**:
   - `PopularPosts`: Retrieves top questions by score for each user.
   - `PostVotes`: Summarizes net votes (upvotes minus downvotes) for each post.
   - `HighScoringPosts`: Joins the two previous CTEs to find each user’s highest scoring question along with its net votes.
   - `UserBadges`: Counts the number of badges owned by each user and aggregates their names.

2. **Main Query**:
   - Joins the `Users`, `HighScoringPosts`, and `UserBadges` to get the required fields.
   - Uses `COALESCE` to handle potential NULLs in cases where users have no posts or badges.
   - Filters users with a reputation greater than 1000 and ensures they have badges.
   - Orders the result by reputation and post score, limiting the output to the top 10 users.

This intricate query tests various SQL constructs including CTEs, aggregates, `LEFT JOIN`, conditional expressions, and sorting, providing a robust benchmark scenario.
