
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId = 6 THEN 1 ELSE 0 END) AS CloseVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostViewStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(UP.TotalVotes, 0) AS UserTotalVotes,
        @row_num := IF(@current_post_id = P.Id, @row_num + 1, 1) AS Rnk,
        @current_post_id := P.Id
    FROM Posts P
    LEFT JOIN UserVoteSummary UP ON P.OwnerUserId = UP.UserId
    CROSS JOIN (SELECT @row_num := 0, @current_post_id := NULL) AS vars
    WHERE P.ViewCount > 100 
    ORDER BY P.LastActivityDate DESC
),
ClosedPostDetails AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        P.Title,
        P.Body
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId = 10 
    AND PH.CreationDate >= CURDATE() - INTERVAL 6 MONTH 
)
SELECT 
    PVS.PostId,
    PVS.Title,
    PVS.ViewCount,
    PVS.UserTotalVotes,
    CPD.CreationDate AS ClosureDate,
    CPD.Body AS ClosedPostBody
FROM PostViewStats PVS
LEFT JOIN ClosedPostDetails CPD ON PVS.PostId = CPD.PostId
WHERE PVS.Rnk = 1 
AND (PVS.UserTotalVotes > 10 OR CPD.PostId IS NOT NULL) 
ORDER BY PVS.ViewCount DESC, PVS.UserTotalVotes DESC;
