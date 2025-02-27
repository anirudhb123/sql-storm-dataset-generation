WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(BadgeCounts.BadgesCount, 0) AS BadgesCount,
        COALESCE(PostCounts.PostsCount, 0) AS PostsCount,
        COALESCE(UpvoteCounts.TotalUpVotes, 0) AS TotalUpVotes,
        COALESCE(DownvoteCounts.TotalDownVotes, 0) AS TotalDownVotes,
        DATEDIFF(MINUTE, U.CreationDate, GETDATE()) AS AccountAgeInMinutes
    FROM Users U
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgesCount 
        FROM Badges 
        GROUP BY UserId
    ) AS BadgeCounts ON U.Id = BadgeCounts.UserId
    LEFT JOIN (
        SELECT 
            OwnerUserId AS UserId, 
            COUNT(*) AS PostsCount 
        FROM Posts 
        GROUP BY OwnerUserId
    ) AS PostCounts ON U.Id = PostCounts.UserId
    LEFT JOIN (
        SELECT 
            UserId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
        FROM Votes 
        GROUP BY UserId
    ) AS UpvoteCounts ON U.Id = UpvoteCounts.UserId
    WHERE U.Reputation IS NOT NULL
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgesCount,
        PostsCount,
        TotalUpVotes,
        TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStats
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgesCount,
    U.PostsCount,
    U.TotalUpVotes,
    U.TotalDownVotes,
    CASE 
        WHEN U.AccountAgeInMinutes IS NULL THEN 'N/A'
        WHEN U.AccountAgeInMinutes < 60 THEN CONCAT(U.AccountAgeInMinutes, ' minutes')
        WHEN U.AccountAgeInMinutes < 1440 THEN CONCAT(FLOOR(U.AccountAgeInMinutes / 60), ' hours')
        ELSE CONCAT(FLOOR(U.AccountAgeInMinutes / 1440), ' days')
    END AS AccountAge,
    (
        SELECT 
            STRING_AGG(P.Title, ', ') 
        FROM Posts P 
        WHERE P.OwnerUserId = U.UserId 
        AND P.PostTypeId = 1
        AND P.ViewCount > 100
        ORDER BY P.Score DESC
        FOR XML PATH(''), TYPE
    ) AS PopularQuestions
FROM TopUsers U
WHERE U.Rank <= 10
ORDER BY U.Rank;

### Explanation of the Query:
1. **CTE `UserStats`:** This common table expression aggregates statistics for users, calculating the count of badges they hold, the number of posts they have authored, and their total votes (both up and down).
   
2. **Partitioning Data:** The data is partitioned by user where applicable, using LEFT JOINs to ensure users without posts or badges are included with zero counts.

3. **Ranking Users:** Another CTE `TopUsers` ranks users based on their reputation.

4. **Selecting and Formatting:** The main selection formats account age into a readable string (e.g., "5 days", "30 minutes") and gathers popular questions authored by each user with more than 100 views.

5. **Final Output:** Filters the top 10 users by rank and orders the results accordingly. It uses `STRING_AGG` to list popular questions, while handling NULL logic through `COALESCE`.

This query showcases various SQL constructs like CTEs, window functions, and conditional expressions, all while delving into performance contexts by aggregating and filtering based on user metrics.
