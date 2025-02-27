
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT CASE WHEN V.VoteTypeId IN (2, 3) THEN V.PostId END) AS TotalPostsVoted,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostsWithHistory AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.Comment AS CloseReason,
        PH.CreationDate AS HistoryDate,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS LatestHistory
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId 
        AND PH.PostHistoryTypeId IN (10, 11) 
    WHERE 
        P.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(ROUND(AVG(CASE WHEN C.Text IS NOT NULL THEN C.Score END), 2), 0) AS AvgCommentScore,
        GROUP_CONCAT(DISTINCT Tags.TagName ORDER BY Tags.TagName SEPARATOR ', ') AS TagList
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', numbers.n), ',', -1)) AS TagName
         FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE 
            CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= numbers.n - 1) Tags ON TRUE
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.ViewCount
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(PW.PostId, -1) AS RecentPostId,
    COALESCE(PW.Title, 'No Recent Post') AS RecentPostTitle,
    COALESCE(PW.CloseReason, 'N/A') AS RecentPostCloseReason,
    UPV.UpVotes,
    UPV.DownVotes,
    PS.ViewCount AS TotalViews,
    PS.AvgCommentScore,
    PS.TagList
FROM 
    UserVoteStats UPV
JOIN 
    Users U ON U.Id = UPV.UserId
LEFT JOIN 
    PostsWithHistory PW ON PW.LatestHistory = 1 AND PW.PostId = U.Id
LEFT JOIN 
    PostStatistics PS ON PS.PostId = PW.PostId
WHERE 
    U.Reputation IS NOT NULL 
    AND (U.Location IS NOT NULL OR U.AboutMe IS NOT NULL) 
ORDER BY 
    UPV.UpVotes DESC, 
    U.Reputation DESC
LIMIT 50;
