WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVotesCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVotesCount,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.Reputation > 1000 -- Only considering users with significant reputation
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(AVG(CASE WHEN C.UserId IS NOT NULL THEN C.Score ELSE NULL END), 0) AS AvgCommentScore
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Only posts created in the last year
    GROUP BY 
        P.Id
),
FinalReport AS (
    SELECT 
        U.DisplayName,
        U.UpVotesCount,
        U.DownVotesCount,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CommentCount,
        P.AvgCommentScore,
        CASE 
            WHEN U.TotalVotes > 100 THEN 'Highly Active' 
            WHEN U.TotalVotes BETWEEN 50 AND 100 THEN 'Moderately Active' 
            ELSE 'Less Active' 
        END AS UserActivityStatus
    FROM 
        UserVotes U
    JOIN 
        PostStatistics P ON U.UserId = P.PostId -- Cross join to see votes on the posts made by this user
)
SELECT 
    DisplayName AS User,
    Title AS PostTitle,
    Score AS PostScore,
    ViewCount AS PostViews,
    CommentCount AS PostComments,
    AvgCommentScore AS AverageCommentScore,
    UserActivityStatus  
FROM 
    FinalReport
WHERE 
    (CommentCount > 10 OR AvgCommentScore > 4) -- Filtering to get engaging posts
ORDER BY 
    Score DESC, 
    ViewCount DESC
FETCH FIRST 50 ROWS ONLY; -- Restricting to top 50 rows for performance benchmarking

-- Consider edge cases, such as unusually high Vote count versus lower Comment counts 
-- Handling NULL values appropriately, ensuring no divide by zero errors in AVG calculations
-- Implement window functions as necessary to further optimize insights into the data
