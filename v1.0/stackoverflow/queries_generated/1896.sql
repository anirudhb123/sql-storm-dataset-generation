WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        TotalBounties,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStatistics
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.Reputation,
    COALESCE(RP.Title, 'No recent posts') AS RecentPostTitle,
    COALESCE(RP.CreationDate, 'N/A') AS RecentPostDate,
    TU.PostCount,
    TU.CommentCount,
    TU.TotalBounties
FROM 
    TopUsers TU
LEFT JOIN 
    RecentPosts RP ON TU.UserId = RP.OwnerUserId AND RP.RecentPostRank = 1
WHERE 
    TU.ReputationRank <= 10
ORDER BY 
    TU.Reputation DESC;

-- Additional metrics using different criteria
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    AVG(P.Score) AS AverageScore,
    COUNT(DISTINCT DISTINCT CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.PostId END) AS ClosedPosts
FROM 
    Users U
INNER JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
GROUP BY 
    U.Id, U.DisplayName
HAVING 
    COUNT(DISTINCT P.Id) > 5 AND AVG(P.Score) > 0
ORDER BY 
    TotalPosts DESC;
