WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(COALESCE(CM.Score, 0)) AS CommentScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments CM ON P.Id = CM.PostId
    GROUP BY 
        U.Id
), 
ActiveUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.CreationDate,
        UA.LastAccessDate,
        UA.PostCount,
        UA.PositivePosts,
        UA.NegativePosts,
        UA.CommentScore,
        RANK() OVER (ORDER BY UA.Reputation DESC) AS ReputationRank
    FROM 
        UserActivity UA
    WHERE 
        UA.LastAccessDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    A.UserId,
    A.DisplayName,
    A.Reputation,
    A.PostCount,
    A.PositivePosts,
    A.NegativePosts,
    A.CommentScore,
    COALESCE(SUM(B.Id), 0) AS BadgeCount,
    CASE 
        WHEN A.Reputation > 1000 THEN 'High Reputation'
        WHEN A.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM 
    ActiveUsers A
LEFT JOIN 
    Badges B ON A.UserId = B.UserId
WHERE 
    A.PostCount > 5
GROUP BY 
    A.UserId, A.DisplayName, A.Reputation, A.PostCount, A.PositivePosts, A.NegativePosts, A.CommentScore
HAVING 
    AVG(A.CommentScore) > 0
ORDER BY 
    A.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

This SQL query constructs a recursive Common Table Expression (CTE) to gather and aggregate user activity data from the `Users`, `Posts`, and `Comments` tables. It then further filters this data for active users based on their last access date, ranks them according to their reputation, and fetches the results based on their badge counts and other metrics. The results are segmented into reputation categories and returns the top 10 results based on reputation.
