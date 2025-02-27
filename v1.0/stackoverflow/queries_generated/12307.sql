-- Performance benchmarking query to analyze user activity and post metrics

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT C.Id) AS TotalComments,
    COUNT(DISTINCT B.Id) AS TotalBadges,
    SUM(V.CreationDate IS NOT NULL) AS TotalVotes,
    AVG(P.Score) AS AveragePostScore,
    SUM(P.ViewCount) AS TotalPostViews,
    SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS TotalPostClosures,
    SUM(CASE WHEN PH.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS TotalPostDeletions,
    MIN(P.CreationDate) AS FirstPostDate,
    MAX(P.LastActivityDate) AS LastPostDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    Reputation DESC;
