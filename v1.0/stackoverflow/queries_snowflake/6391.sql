
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
        TRIM(REGEXP_SUBSTR(P.Tags, '[^><]+', 1, seq)) AS TagName
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    JOIN (SELECT DISTINCT POST.Id, 
                 ROW_NUMBER() OVER (PARTITION BY POST.Id ORDER BY seq) AS seq 
          FROM (
              SELECT P.Id, 
                     SEQ4() AS seq 
              FROM Posts P, 
                   TABLE(GENERATOR(ROWCOUNT => 1000)) -- Adjust the row count based on maximum tags
          ) POST ) T ON T.Id = P.Id
    WHERE T.seq <= ARRAY_SIZE(split(P.Tags, '><'))  -- To limit based on the number of tags
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
