
WITH UserSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
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
        @rank := IF(@prev_rank = Reputation, @rank, @rank + 1) AS ReputationRank,
        @prev_rank := Reputation
    FROM UserSummary
    CROSS JOIN (SELECT @rank := 0, @prev_rank := NULL) r
    ORDER BY Reputation DESC
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
    JOIN (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS TagName, P.Id 
          FROM Posts P 
          INNER JOIN (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                      UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
          ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1) T 
    ON T.Id = P.Id
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
LEFT JOIN RecentPostDetails RPD ON TU.DisplayName = RPD.OwnerName
WHERE TU.ReputationRank <= 10
ORDER BY TU.Reputation DESC, RPD.CreationDate DESC;
