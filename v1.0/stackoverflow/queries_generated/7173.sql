WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COALESCE(COUNT(DISTINCT B.Id), 0) AS TotalBadges,
        COUNT(DISTINCT P.Id) AS TotalPosts
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalBounty, 
        TotalBadges, 
        TotalPosts,
        RANK() OVER (ORDER BY Reputation DESC) AS RankByReputation
    FROM 
        UserStats
)
SELECT 
    U.*, 
    COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseVoteCount,
    COUNT(CASE WHEN PH.PostHistoryTypeId = 12 THEN 1 END) AS DeleteVoteCount,
    T.TagName
FROM 
    TopUsers U
JOIN 
    Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    (SELECT P.Id, unnest(string_to_array(P.Tags, ',')) AS TagName 
     FROM Posts P WHERE P.Tags IS NOT NULL) T ON P.Id = T.Id
WHERE 
    U.RankByReputation <= 10
GROUP BY 
    U.UserId, U.DisplayName, U.Reputation, U.TotalBounty, U.TotalBadges, U.TotalPosts, T.TagName
ORDER BY 
    U.RankByReputation;
