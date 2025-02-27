WITH UserRankings AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
), HighReputationUsers AS (
    SELECT 
        UserId,
        DisplayName
    FROM UserRankings
    WHERE ReputationRank <= 10
), RecentPostCounts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS RecentPostsCount
    FROM Posts P
    WHERE P.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY P.OwnerUserId
), CombinedData AS (
    SELECT 
        U.DisplayName,
        COALESCE(R.RecentPostsCount, 0) AS RecentPostsCount,
        COALESCE(B.BadgesCount, 0) AS BadgesCount,
        R.ReputationRank
    FROM HighReputationUsers U
    LEFT JOIN RecentPostCounts R ON U.UserId = R.OwnerUserId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgesCount
        FROM Badges
        GROUP BY UserId
    ) B ON U.UserId = B.UserId
)
SELECT 
    CD.DisplayName,
    CD.RecentPostsCount,
    CD.BadgesCount,
    CASE 
        WHEN CD.RecentPostsCount = 0 THEN 'No posts in the last 30 days'
        ELSE 'Active user'
    END AS ActivityStatus,
    (SELECT STRING_AGG(T.TagName, ', ') 
     FROM Tags T 
     WHERE T.WikiPostId IS NOT NULL) AS PopularTags,
    (SELECT COUNT(*) 
     FROM Votes V 
     WHERE V.CreationDate > NOW() - INTERVAL '7 days' 
     AND V.VoteTypeId = 2) AS RecentUpVotes,
    (SELECT count(*) 
     FROM PostHistory PH 
     WHERE PH.UserId IN (SELECT U.Id 
                         FROM Users U 
                         WHERE U.Reputation > 1000) 
     AND PH.CreationDate > NOW() - INTERVAL '90 days') AS HistoryCommentsFromHighReputationUsers
FROM CombinedData CD
ORDER BY CD.ReputationRank;

### Explanation:
- **CTEs** (`UserRankings`, `HighReputationUsers`, `RecentPostCounts`, `CombinedData`) are used to structure the query for readability and to aggregate related data efficiently.
- **UserRankings** ranks users based on their reputation.
- **HighReputationUsers** filters for only the top users.
- **RecentPostCounts** counts the number of posts by users created in the last 30 days.
- **CombinedData** merges data from users, their recent posts count, and their badge counts.
- The main query selects user details while also including:
  - A case expression for user activity status.
  - Subqueries to aggregate popular tags, recent upvotes, and comments by high-reputation users from the post history table.
- **NULL logic** is handled with `COALESCE` for the counts to avoid showing null values.
- The use of window functions for ranking and the `STRING_AGG` function for popular tags adds complexity to the query, showcasing advanced SQL techniques.
