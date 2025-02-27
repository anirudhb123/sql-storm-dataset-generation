
WITH UserVotes AS (
    SELECT 
        U.Id AS UserId, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT POST.Id) AS PostsCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts POST ON V.PostId = POST.Id
    WHERE U.Reputation > 1000
    GROUP BY U.Id
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        LEAD(P.CreationDate) OVER (ORDER BY P.CreationDate DESC) AS NextCreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rn
    FROM Posts P
    WHERE P.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY)
),
ClosedPosts AS (
    SELECT 
        PH.PostId, 
        COUNT(*) AS CloseCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
)
SELECT 
    U.DisplayName, 
    UV.UpVotesCount, 
    UV.DownVotesCount, 
    RP.Title AS RecentPostTitle,
    RP.Score AS RecentPostScore,
    COALESCE(CP.CloseCount, 0) AS PostCloseCount,
    CASE 
        WHEN UV.UpVotesCount - UV.DownVotesCount > 100 THEN 'Highly Active'
        WHEN UV.UpVotesCount - UV.DownVotesCount BETWEEN 50 AND 100 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel,
    GROUP_CONCAT(DISTINCT T.TagName ORDER BY T.TagName SEPARATOR ', ') AS Tags
FROM UserVotes UV
JOIN Users U ON U.Id = UV.UserId
LEFT JOIN RecentPosts RP ON RP.Rn = 1 
LEFT JOIN ClosedPosts CP ON CP.PostId = RP.PostId
LEFT JOIN Posts P ON P.OwnerUserId = U.Id
LEFT JOIN (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', numbers.n), ',', -1)) AS TagName
    FROM 
    (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers INNER JOIN Posts P ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= numbers.n - 1
) T ON TRUE
WHERE UV.PostsCount > 5
GROUP BY U.DisplayName, UV.UpVotesCount, UV.DownVotesCount, RP.Title, RP.Score, CP.CloseCount
HAVING COUNT(DISTINCT P.Id) > 2
ORDER BY ActivityLevel DESC, UV.UpVotesCount DESC;
