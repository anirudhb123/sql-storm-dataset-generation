WITH RecursiveUserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN P.Score < 0 THEN abs(P.Score) ELSE 0 END) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(P.Id) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
), 
RecentPostHistories AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        P.Title,
        PH.CreationDate,
        PH.UserDisplayName,
        RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) as Rank
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    U.DisplayName,
    UPS.PostCount,
    UPS.TotalUpVotes,
    UPS.TotalDownVotes,
    COALESCE(Ranking.Rank, 0) AS HistoryChangeRank,
    AVG(PH_CreationChange) AS AvgPostCreationTimeChange,
    STRING_AGG(PH.Title, ', ') AS RecentChanges
FROM 
    RecursiveUserPostStats UPS
LEFT JOIN 
    RecentPostHistories PH ON UPS.UserId = PH.UserId
FULL OUTER JOIN 
    (SELECT 
         PostId, COUNT(*) AS Rank
     FROM 
         RecentPostHistories
     WHERE 
         Rank = 1
     GROUP BY 
         PostId) AS Ranking ON PH.PostId = Ranking.PostId
GROUP BY 
    U.DisplayName, UPS.PostCount, UPS.TotalUpVotes, UPS.TotalDownVotes
ORDER BY 
    UPS.TotalUpVotes DESC, AvgPostCreationTimeChange DESC
LIMIT 100;

This SQL query does the following:

1. Defines a recursive Common Table Expression (CTE) `RecursiveUserPostStats` that aggregates user statistics based on the number of posts they have created and their corresponding upvotes and downvotes, limited to users with a reputation greater than 1000.
  
2. Defines another CTE `RecentPostHistories` that captures the most recent history changes of posts created in the last year, with a rank assigned to each history change per post.

3. Joins the two CTEs to get a comprehensive view of active users, their post statistics, and their most recent contributions to posts including a rank that indicates the most recent change to their posts.

4. Uses string aggregation to compile recent changes made to posts by each user into a single comma-separated string.

5. Uses COALESCE to handle cases where there may be no changes, thus defaulting to zero.

6. Finally, it orders by total upvotes and average creation time change, limiting the results to the top 100 users based on their contributions and activity.
