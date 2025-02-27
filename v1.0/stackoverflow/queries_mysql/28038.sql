
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN VT.Name = 'Favorite' THEN 1 ELSE 0 END) AS Favorites
    FROM 
        Users U
        LEFT JOIN Votes V ON U.Id = V.UserId
        LEFT JOIN VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostTagStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.AcceptedAnswerId,
        GROUP_CONCAT(DISTINCT TRIM(T.TagName) SEPARATOR ',') AS Tags,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.Score
    FROM 
        Posts P
        LEFT JOIN (
            SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '>', n.n), '>', -1)) AS TagName
            FROM Posts P
            INNER JOIN (
                SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
                UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
            ) n ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '>', '')) >= n.n - 1
        ) AS TagTag ON TRUE
        LEFT JOIN Tags T ON T.TagName = TRIM(TagTag.TagName)
    GROUP BY 
        P.Id, P.Title, P.AcceptedAnswerId, P.CreationDate, P.ViewCount, P.AnswerCount, P.Score
),
RecentActivity AS (
    SELECT 
        P.Id AS PostId,
        MAX(CA.CreationDate) AS LastActivityDate,
        COUNT(CM.Id) AS CommentCount,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        Posts P
        LEFT JOIN Comments CM ON P.Id = CM.PostId
        LEFT JOIN PostHistory PH ON P.Id = PH.PostId
        LEFT JOIN Posts CA ON P.AcceptedAnswerId = CA.Id
    WHERE 
        P.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
    GROUP BY 
        P.Id
)
SELECT 
    U.DisplayName AS User,
    U.Reputation,
    U.TotalVotes,
    U.UpVotes,
    U.DownVotes,
    U.Favorites,
    P.Title,
    P.Tags,
    P.ViewCount,
    P.AnswerCount,
    P.Score,
    R.LastActivityDate,
    R.CommentCount,
    R.HistoryCount
FROM 
    UserVoteStats U
    JOIN PostTagStats P ON U.UserId = P.AcceptedAnswerId
    JOIN RecentActivity R ON P.PostId = R.PostId
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC, R.LastActivityDate DESC
LIMIT 100;
