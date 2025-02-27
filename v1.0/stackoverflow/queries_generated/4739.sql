WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS TotalPosts, 
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(V.Id IS NOT NULL, 0)::int) AS TotalVotes,
        SUM(COALESCE(B.Class, 0)) AS TotalBadges,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CreationDate,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS PopularityRank
    FROM Posts P
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
),
TopUsers AS (
    SELECT 
        UA.UserId, 
        UA.DisplayName, 
        UA.Reputation, 
        UA.TotalPosts, 
        UA.TotalComments, 
        UA.TotalVotes, 
        UA.TotalBadges,
        UA.UserRank
    FROM UserActivity UA
    WHERE UA.UserRank <= 10
)
SELECT 
    PU.PostId,
    PU.Title,
    PU.Score,
    PU.ViewCount,
    COALESCE(TU.DisplayName, 'Anonymous') AS TopUserDisplayName,
    COALESCE(TU.Reputation, 0) AS TopUserReputation,
    (SELECT COUNT(*) FROM Votes WHERE PostId = PU.PostId AND VoteTypeId = 2) AS Upvotes,
    (SELECT COUNT(*) FROM Votes WHERE PostId = PU.PostId AND VoteTypeId = 3) AS Downvotes
FROM PopularPosts PU
LEFT JOIN TopUsers TU ON PU.Title ILIKE '%' || TU.DisplayName || '%'
WHERE PU.PopularityRank <= 5
ORDER BY PU.ViewCount DESC, PU.CreationDate DESC
;
