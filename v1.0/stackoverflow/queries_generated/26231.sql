WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts, 
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(V.VoteCount, 0)) AS TotalVotes,
        SUM(COALESCE(B.Class, 0)) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM Votes 
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 100
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalPosts, 
        TotalComments,
        TotalVotes,
        TotalBadges,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserReputation
    WHERE TotalPosts > 5 AND TotalVotes > 10
)
SELECT 
    TU.Rank,
    TU.DisplayName,
    TU.Reputation,
    TU.TotalPosts,
    TU.TotalComments,
    TU.TotalVotes,
    TU.TotalBadges,
    (SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
     FROM Posts P 
     JOIN LATERAL (
         SELECT UNNEST(STRING_TO_ARRAY(P.Tags, '><')) AS TagName
     ) AS T ON P.Id = T.TagId
     WHERE P.OwnerUserId = TU.UserId) AS FrequentlyUsedTags
FROM TopUsers TU
WHERE TU.Rank <= 10
ORDER BY TU.Rank;
