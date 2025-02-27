WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS TotalBadges, 
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN p.ViewCount ELSE 0 END) AS TotalViews,
        AVG(p.Score) FILTER (WHERE p.Score IS NOT NULL) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
RecentVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        ROW_NUMBER() OVER (PARTITION BY v.UserId ORDER BY v.CreationDate DESC) AS VoteRank
    FROM Votes v
    GROUP BY v.UserId
)
SELECT 
    u.DisplayName AS UserName,
    COALESCE(ub.TotalBadges, 0) AS TotalBadges,
    COALESCE(ub.BadgeNames, 'None') AS BadgeNames,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    COALESCE(ps.AvgScore, 0) AS AvgScore,
    rv.TotalVotes AS RecentVoteCount,
    rv.UpVotesCount,
    rv.DownVotesCount,
    CASE 
        WHEN rv.TotalVotes IS NOT NULL AND rv.TotalVotes > 0 THEN 'Active Voter'
        ELSE 'Inactive Voter'
    END AS VotingStatus
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN RecentVotes rv ON u.Id = rv.UserId
WHERE u.Reputation > 1000
AND (rv.VoteRank IS NULL OR rv.VoteRank <= 5)  -- Recent votes within last 5
ORDER BY u.Reputation DESC, TotalPosts DESC;

### Explanation:

1. **Common Table Expressions (CTEs)**:
   - `UserBadges`: This CTE aggregates the total number of badges each user has and concatenates badge names.
   - `PostStats`: Counts posts, questions, answers, views, and averages the score per user.
   - `RecentVotes`: Calculates the total votes for each user and distinguishes between upvotes and downvotes, ranking them by the latest voting date.

2. **SELECT Statement**:
   - Fetches user details along with badge counts, post statistics, and recent vote information.
   - Uses `COALESCE` to handle NULL scenarios, providing default values, like 'None' for badge names and 0 for counts.
   - Establishes a case logic to classify users as either 'Active Voter' if they have voted recently or 'Inactive Voter' otherwise.

3. **WHERE Clause**: Filters users with a reputation greater than 1000 and recent voting activity.

4. **ORDER BY**: Sorts users by reputation and total posts in descending order.

Slightly obscure cases or SQL behaviors, such as filtered aggregations and handling NULL values effectively, were employed to show complexity in logic and usage.
