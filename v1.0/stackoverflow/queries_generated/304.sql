WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostCount,
        (SELECT SUM(V.BountyAmount) FROM Votes V WHERE V.UserId = U.Id) AS TotalBounties
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalBounties,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserScores
    WHERE 
        PostCount > 5
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerName,
        P.ViewCount,
        COALESCE(P.ClosedDate, 'No Closed Date') AS ClosedStatus
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    R.PostId,
    R.Title,
    R.CreationDate,
    R.Score,
    R.ViewCount,
    R.ClosedStatus
FROM 
    TopUsers T
JOIN 
    RecentPosts R ON T.UserId = R.OwnerName
WHERE 
    R.Score > 0
ORDER BY 
    T.Rank, R.CreationDate DESC;

-- This complex SQL query retrieves top users based on reputation who have 
-- a significant number of posts in the last 30 days and their recent active posts.
