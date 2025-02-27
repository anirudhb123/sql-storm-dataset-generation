WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS Upvotes,
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), RankedPosts AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        Questions,
        Answers,
        TotalViews,
        Upvotes,
        Downvotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
), TopUsers AS (
    SELECT 
        *,
        CASE 
            WHEN Reputation >= 1000 THEN 'Gold'
            WHEN Reputation >= 500 THEN 'Silver'
            ELSE 'Bronze' 
        END AS Badge
    FROM 
        RankedPosts
    WHERE 
        TotalPosts > 10
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.Badge,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.TotalViews,
    U.Upvotes,
    U.Downvotes,
    (U.Upvotes::float / NULLIF(U.TotalPosts, 0)) * 100 AS UpvotePercentage
FROM 
    TopUsers U
WHERE 
    U.ReputationRank <= 50
ORDER BY 
    U.Reputation DESC, U.DisplayName
LIMIT 20;
