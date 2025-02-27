WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT COALESCE(C.Amt, 0)) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Upvotes,
        Downvotes,
        TotalPosts,
        TotalComments,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserReputation U
    INNER JOIN Users ON U.UserId = Users.Id
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.Upvotes - T.Downvotes AS NetVotes,
    T.TotalPosts,
    T.TotalComments,
    CASE 
        WHEN T.Rank <= 10 THEN 'Top Contributors'
        ELSE 'Regular Contributors'
    END AS ContributorType
FROM TopUsers T
JOIN (SELECT userId, COUNT(*) AS CommentCount FROM Comments GROUP BY userId HAVING COUNT(*) > 5) AS FrequentCommenters ON T.UserId = FrequentCommenters.UserId
LEFT JOIN PostHistory PH ON T.UserId = PH.UserId AND PH.CreationDate > NOW() - INTERVAL '30 days'
WHERE T.TotalPosts > 5
ORDER BY T.Reputation DESC,
         NetVotes DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
