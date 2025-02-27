
WITH RECURSIVE UserReputations AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        1 AS ReputationLevel
    FROM Users U
    WHERE U.Reputation > 0

    UNION ALL

    SELECT 
        UR.UserId,
        UR.Reputation + 100 AS Reputation,
        ReputationLevel + 1
    FROM UserReputations UR
    WHERE UR.Reputation < 1000
),
PostSummaries AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS RN
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= '2023-01-01'
    GROUP BY P.Id, P.Title, P.CreationDate, U.DisplayName, P.Score
),
TagPostCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '>', numbers.n), '>', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts P
    JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
        SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL 
        SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '>', '')) >= numbers.n - 1
    GROUP BY TagName
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        COUNT(PH.Comment) AS TotalCloseComments
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.PostId, PH.CreationDate
)
SELECT 
    PS.PostId, 
    PS.Title, 
    PS.CreationDate,
    PS.DisplayName,
    PS.Score,
    PS.CommentCount,
    COALESCE(CP.TotalCloseComments, 0) AS TotalCloseComments,
    COALESCE(TPC.PostCount, 0) AS TagPostCount,
    UR.ReputationLevel
FROM PostSummaries PS
LEFT JOIN ClosedPosts CP ON PS.PostId = CP.PostId
LEFT JOIN TagPostCounts TPC ON TPC.TagName IN (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(PS.Title, ' ', numbers.n), ' ', -1) 
                                               FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
                                                     SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL 
                                                     SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
                                               WHERE CHAR_LENGTH(PS.Title) - CHAR_LENGTH(REPLACE(PS.Title, ' ', '')) >= numbers.n - 1)
LEFT JOIN UserReputations UR ON PS.DisplayName = UR.UserId
WHERE PS.RN = 1
ORDER BY PS.CreationDate DESC
LIMIT 100;
