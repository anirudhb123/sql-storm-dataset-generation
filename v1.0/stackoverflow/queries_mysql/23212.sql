
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(U.Reputation) AS AvgReputation
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        MAX(P.CreationDate) as LatestDate,
        GROUP_CONCAT(DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '>', numbers.n), '>', -1))) AS Tags
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
          SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '>', '')) >= numbers.n - 1
    GROUP BY P.Id, P.Title, P.PostTypeId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(PH.Id) AS CloseCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11)  
    GROUP BY PH.PostId, PH.PostHistoryTypeId
),
PostRankings AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CommentCount,
        PS.TotalScore,
        PS.Tags,
        CASE 
            WHEN CP.CloseCount IS NOT NULL THEN 'Closed' 
            ELSE 'Active' 
        END AS PostStatus
    FROM PostStatistics PS
    LEFT JOIN (
        SELECT PostId, MAX(CloseCount) AS CloseCount 
        FROM ClosedPosts 
        GROUP BY PostId
    ) CP ON PS.PostId = CP.PostId
)
SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.TotalVotes,
    UR.UpVotes,
    UR.DownVotes,
    PR.PostId,
    PR.Title,
    PR.CommentCount,
    PR.TotalScore,
    PR.Tags,
    PR.PostStatus,
    CASE 
        WHEN UR.UpVotes > 0 THEN 'Highly Engaged'
        WHEN UR.DownVotes > 0 THEN 'Critically Engaged'
        ELSE 'Lurker'
    END AS EngagementLevel
FROM UserVoteStats UR
JOIN PostRankings PR ON UR.TotalVotes > 0
ORDER BY 
    UR.TotalVotes DESC,
    PR.TotalScore DESC,
    PR.CommentCount DESC
LIMIT 50;
