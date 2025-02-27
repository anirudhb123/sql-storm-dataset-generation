WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.VoteTypeId = 2) AS Upvotes,
        SUM(V.VoteTypeId = 3) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ClosedPosts AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS ClosedPostCount,
        MAX(PH.CreationDate) AS LastCloseDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.UserId
),
RankedUsers AS (
    SELECT 
        Us.UserId,
        Us.DisplayName,
        Us.Reputation,
        Us.TotalPosts,
        Us.TotalComments,
        Us.Upvotes,
        Us.Downvotes,
        COALESCE(CP.ClosedPostCount, 0) AS ClosedPostCount,
        RANK() OVER (ORDER BY Us.Reputation DESC) AS ReputationRank
    FROM 
        UserStats Us
    LEFT JOIN 
        ClosedPosts CP ON Us.UserId = CP.UserId
)
SELECT 
    RU.DisplayName,
    RU.Reputation,
    RU.TotalPosts,
    RU.TotalComments,
    RU.Upvotes,
    RU.Downvotes,
    RU.ClosedPostCount,
    CASE 
        WHEN RU.TotalPosts > 100 THEN 'Frequent Contributor'
        WHEN RU.ClosedPostCount > 5 THEN 'Active Closer'
        ELSE 'Regular User'
    END AS UserCategory,
    DENSE_RANK() OVER (ORDER BY RU.LastCloseDate DESC NULLS LAST) AS RecentClosers
FROM 
    RankedUsers RU
WHERE 
    RU.Reputation > 100
ORDER BY 
    RU.Reputation DESC, UserCategory asc;
