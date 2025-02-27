-- Performance benchmarking query to analyze user activity
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT C.Id) AS TotalComments,
    SUM(V.VoteTypeId = 2) AS TotalUpVotes,
    SUM(V.VoteTypeId = 3) AS TotalDownVotes,
    SUM(B.Class = 1) AS TotalGoldBadges,
    SUM(B.Class = 2) AS TotalSilverBadges,
    SUM(B.Class = 3) AS TotalBronzeBadges,
    MAX(P.CreationDate) AS LastPostDate
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    U.Reputation > 0
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalPosts DESC, TotalUpVotes DESC;
