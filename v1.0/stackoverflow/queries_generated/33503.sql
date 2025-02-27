WITH RecursiveUserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostsCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.UserId = U.Id) AS CommentsCount,
        0 AS Level
    FROM Users U
    WHERE U.Reputation > 1000
    
    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostsCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.UserId = U.Id) AS CommentsCount,
        Level + 1
    FROM Users U
    JOIN RecursiveUserStats R ON U.Id = R.UserId
    WHERE U.Reputation > 1000
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.Views,
    U.UpVotes,
    U.DownVotes,
    COALESCE(U.PostsCount, 0) AS TotalPosts,
    COALESCE(U.CommentsCount, 0) AS TotalComments,
    RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
    STRING_AGG(T.TagName, ', ') AS PopularTags,
    (SELECT COUNT(*) FROM Votes V WHERE V.UserId = U.Id AND V.VoteTypeId = 2) AS TotalUpVotes,
    (SELECT COUNT(*) FROM Votes V WHERE V.UserId = U.Id AND V.VoteTypeId = 3) AS TotalDownVotes,
    CASE 
        WHEN U.Reputation > 5000 THEN 'High'
        WHEN U.Reputation BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'Low'
    END AS ReputationLevel
FROM RecursiveUserStats U
LEFT JOIN Posts P ON P.OwnerUserId = U.UserId
LEFT JOIN Tags T ON T.Id IN (SELECT unnest(string_to_array(P.Tags, ',')::int[]))
WHERE U.Views > 50
GROUP BY U.UserId, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
ORDER BY ReputationRank
LIMIT 100;
