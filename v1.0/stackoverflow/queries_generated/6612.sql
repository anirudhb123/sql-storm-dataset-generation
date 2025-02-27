WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation >= 100
    GROUP BY U.Id, U.DisplayName, U.Reputation
), ActiveUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.TotalPosts,
        UA.TotalComments,
        UA.UpVotes,
        UA.DownVotes,
        UA.TotalBadges,
        ROW_NUMBER() OVER (ORDER BY UA.Reputation DESC) AS UserRank
    FROM UserActivity UA
    WHERE UA.TotalPosts > 0
)
SELECT 
    A.UserId,
    A.DisplayName,
    A.Reputation,
    A.TotalPosts,
    A.TotalComments,
    A.UpVotes,
    A.DownVotes,
    A.TotalBadges,
    A.UserRank,
    P.Title AS LatestPostTitle,
    P.CreationDate AS LatestPostDate
FROM ActiveUsers A
LEFT JOIN Posts P ON A.UserId = P.OwnerUserId
WHERE P.CreationDate = (SELECT MAX(P2.CreationDate) FROM Posts P2 WHERE P2.OwnerUserId = A.UserId)
ORDER BY A.UserRank
LIMIT 10;
