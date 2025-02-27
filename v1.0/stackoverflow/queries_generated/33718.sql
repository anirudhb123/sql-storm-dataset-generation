WITH RECURSIVE UserPostCounts AS (
    SELECT OwnerUserId AS UserId, COUNT(Id) AS PostCount
    FROM Posts
    GROUP BY OwnerUserId
),
UserReputation AS (
    SELECT Id, Reputation, DisplayName, LastAccessDate, CreationDate
    FROM Users
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(PH.Comment, 'No comments') AS LastComment,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.LastActivityDate DESC) AS LastActivityRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        SUM(PostCount) AS TotalPosts
    FROM UserPostCounts
    GROUP BY UserId
    ORDER BY TotalPosts DESC
    LIMIT 5
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    U.LastAccessDate,
    P.PostId,
    P.Title,
    P.PostCreationDate,
    P.ViewCount,
    P.Score,
    P.LastComment
FROM UserReputation U
INNER JOIN TopUsers TU ON U.Id = TU.UserId
LEFT OUTER JOIN PostStatistics P ON U.Id = P.OwnerUserId
WHERE P.LastActivityRank = 1
ORDER BY U.Reputation DESC, P.ViewCount DESC
LIMIT 10;
