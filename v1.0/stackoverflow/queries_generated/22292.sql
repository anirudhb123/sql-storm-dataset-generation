WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
), RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentRank
    FROM Posts P
    WHERE P.CreationDate > CURRENT_DATE - INTERVAL '30 days'
), ClosedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        PH.CreationDate AS ClosedDate,
        MAX(PH.CreationDate) OVER (PARTITION BY PH.PostId) AS MaxClosedDate
    FROM Posts P
    JOIN PostHistory PH ON PH.PostId = P.Id AND PH.PostHistoryTypeId = 10
    WHERE P.PostTypeId = 1
), TagUsage AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS UsageCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 5
), UpvotedPosts AS (
    SELECT 
        P.Id,
        COUNT(V.UserId) AS UpvoteCount
    FROM Posts P
    JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2
    GROUP BY P.Id
), ActiveUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.PostCount,
        UA.TotalBounty,
        UA.UpVotes,
        UA.DownVotes,
        COALESCE(RP.RecentRank, 0) AS RecentPostRank,
        COALESCE(CP.ClosedDate, NULL) AS ClosedPostDate
    FROM UserActivity UA
    LEFT JOIN RecentPosts RP ON UA.UserId = RP.OwnerUserId
    LEFT JOIN ClosedPosts CP ON UA.UserId = CP.Id
)
SELECT 
    AU.UserId,
    AU.DisplayName,
    AU.PostCount,
    AU.TotalBounty,
    AU.UpVotes,
    AU.DownVotes,
    AU.RecentPostRank,
    AU.ClosedPostDate,
    TG.TagName,
    COALESCE(UP.UpvoteCount, 0) AS UpvoteCount
FROM ActiveUsers AU
LEFT JOIN TagUsage TG ON AU.PostCount > 10 AND TG.UsageCount > 5
LEFT JOIN UpvotedPosts UP ON AU.UserId = UP.OwnerUserId
WHERE AU.TotalBounty IS NOT NULL 
AND (AU.PostCount > 0 OR AU.UpVotes > 5)
ORDER BY AU.PostCount DESC, AU.TotalBounty DESC, AU.UpVotes DESC 
FETCH FIRST 100 ROWS ONLY;

### Explanation:
- **CTEs (Common Table Expressions)**: 
  - `UserActivity`: Collects user statistics with post counts and total bounty amounts.
  - `RecentPosts`: Fetches posts created in the last 30 days and ranks them per user.
  - `ClosedPosts`: Identifies closed questions and when they were closed.
  - `TagUsage`: Aggregates tags that are used in more than 5 posts.
  - `UpvotedPosts`: Counts upvotes for each post.
  - `ActiveUsers`: Joins user activity, recent posts, and closed posts.

- **Final SELECT**: Combines results from `ActiveUsers`, tag usage, and upvoted posts to display extensive information about active users, filtering based on user activity and post characteristics.

- **Null Logic**: Utilizes `COALESCE` to ensure meaningful results in the presence of NULLs, especially for newly active users or users without posts.

- **Unusual constructs**: The use of the `LIKE` operator within `Tags` and the complex handle of random logic makes the query intriguing, while ensuring a diverse output featuring varied user activity over time.
