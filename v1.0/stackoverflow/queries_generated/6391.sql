WITH UserSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVoteCount,
        SUM(V.VoteTypeId = 3) AS DownVoteCount,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        CommentCount, 
        UpVoteCount, 
        DownVoteCount, 
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserSummary
),
RecentPostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerName,
        T.TagName,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    JOIN LATERAL unnest(string_to_array(P.Tags, '><')) AS T(TagName) ON TRUE
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.CommentCount,
    TU.UpVoteCount,
    TU.DownVoteCount,
    TU.BadgeCount,
    RPD.PostId,
    RPD.Title,
    RPD.CreationDate,
    RPD.Score,
    RPD.OwnerName,
    RPD.TagName
FROM TopUsers TU
LEFT JOIN RecentPostDetails RPD ON TU.UserId = RPD.OwnerName
WHERE TU.ReputationRank <= 10
ORDER BY TU.Reputation DESC, RPD.CreationDate DESC;
