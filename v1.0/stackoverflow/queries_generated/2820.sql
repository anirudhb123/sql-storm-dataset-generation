WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        U.CreationDate, 
        COUNT(DISTINCT P.Id) AS TotalPosts, 
        COUNT(DISTINCT C.Id) AS TotalComments, 
        SUM(COALESCE(VB.VoteCount, 0)) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) VB ON P.Id = VB.PostId
    GROUP BY 
        U.Id
), TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserStatistics
), RecentPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.Score, 
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
), AggregatedPostData AS (
    SELECT 
        T.UserId,
        T.DisplayName,
        COUNT(RP.PostId) AS RecentPostsCount,
        SUM(RP.Score) AS TotalScores
    FROM 
        TopUsers T
    LEFT JOIN 
        RecentPosts RP ON T.UserId = RP.OwnerDisplayName
    GROUP BY 
        T.UserId, T.DisplayName
)
SELECT 
    APS.DisplayName, 
    APS.RecentPostsCount, 
    APS.TotalScores,
    CASE 
        WHEN APS.RecentPostsCount > 5 THEN 'Active'
        ELSE 'Less Active'
    END AS ActivityStatus,
    U.Reputation
FROM 
    AggregatedPostData APS
JOIN 
    Users U ON APS.DisplayName = U.DisplayName
WHERE 
    U.Location IS NOT NULL AND 
    U.Reputation > 1000
ORDER BY 
    APS.TotalScores DESC, APS.RecentPostsCount DESC;
