
WITH RECURSIVE UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
        LEFT JOIN Votes V ON U.Id = V.UserId
        LEFT JOIN Posts P ON V.PostId = P.Id
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
PostWithTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        GROUP_CONCAT(T.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts P
        LEFT JOIN Tags T ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score
),
RecentPostStatistics AS (
    SELECT 
        P.PostId, 
        P.Title,
        P.CreationDate,
        P.Score,
        UP.UserId,
        UP.DisplayName,
        @rank := IF(@prevUser = UP.UserId, @rank + 1, 1) AS PostRank,
        @prevUser := UP.UserId,
        CASE 
            WHEN PH.PostId IS NOT NULL THEN 'Edited'
            ELSE 'New'
        END AS PostStatus
    FROM 
        PostWithTags P
        LEFT JOIN UserVotes UP ON P.Score > (SELECT AVG(Score) FROM Posts)
        LEFT JOIN PostHistory PH ON P.PostId = PH.PostId,
        (SELECT @rank := 0, @prevUser := NULL) AS vars
    WHERE 
        P.CreationDate > (NOW() - INTERVAL 30 DAY)
)
SELECT 
    R.DisplayName, 
    COUNT(R.PostId) AS EditedPostCount,
    SUM(CASE WHEN R.PostStatus = 'Edited' THEN 1 ELSE 0 END) AS EditedPosts,
    SUM(CASE WHEN R.PostStatus = 'New' THEN 1 ELSE 0 END) AS NewPosts,
    AVG(R.Score) AS AveragePostScore
FROM 
    RecentPostStatistics R
    JOIN UserVotes U ON R.UserId = U.UserId
GROUP BY 
    R.DisplayName
ORDER BY 
    EditedPostCount DESC;
