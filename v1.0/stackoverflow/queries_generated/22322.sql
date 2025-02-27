WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS TotalVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
), 
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COUNT(C.Comments) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        AVG(P.Score) OVER (PARTITION BY P.OwnerUserId) AS AverageScore,
        CASE 
            WHEN P.ClosedDate IS NOT NULL THEN 'Closed' 
            ELSE 'Open' 
        END AS PostStatus
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
UserPostInteractions AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN PS.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS PostsInteracted,
        Coalesce(SUM(CASE WHEN PS.PostStatus = 'Closed' THEN 1 ELSE 0 END), 0) AS ClosedPosts,
        Coalesce(SUM(CASE WHEN PS.PostStatus = 'Open' THEN 1 ELSE 0 END), 0) AS OpenPosts
    FROM 
        Users U
    LEFT JOIN 
        PostStatistics PS ON U.Id = PS.OwnerUserId
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName,
    UVC.TotalVotes,
    UVC.UpVotes,
    UVC.DownVotes,
    UPI.PostsInteracted,
    UPI.ClosedPosts,
    UPI.OpenPosts,
    ROW_NUMBER() OVER (ORDER BY UVC.TotalVotes DESC) AS Rank
FROM 
    UserVoteCounts UVC
JOIN 
    UserPostInteractions UPI ON UVC.UserId = UPI.UserId
WHERE 
    UVC.TotalVotes > 5
ORDER BY 
    Rank;
This query includes several advanced SQL features: 
- **Common Table Expressions (CTE)** are utilized for organizing user vote counts and post statistics.
- The **window function** `ROW_NUMBER()` ranks users based on their total votes.
- **Outer joins** are used to include users without any votes or posts.
- **Aggregation** and conditional summation help analyze user interactions with posts.
- **Case statements** classify posts as ‘Closed’ or 'Open' based on null checks on `ClosedDate`.
- **Coalescing** is employed to ensure non-null outputs, even when no interactions exist.
