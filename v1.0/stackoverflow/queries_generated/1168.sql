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
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.LastActivityDate DESC) AS Rnk
    FROM Posts P
    LEFT JOIN UserVoteSummary UP ON P.OwnerUserId = UP.UserId
    WHERE P.ViewCount > 100 -- Filter for popular posts
),
ClosedPostDetails AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        P.Title,
        P.Body
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId = 10 -- Closed posts
    AND PH.CreationDate >= CURRENT_DATE - INTERVAL '6 months' -- Closed in the last 6 months
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
WHERE PVS.Rnk = 1 -- Only the latest activity of the post 
AND (PVS.UserTotalVotes > 10 OR CPD.PostId IS NOT NULL) -- Either has many votes or is closed
ORDER BY PVS.ViewCount DESC, PVS.UserTotalVotes DESC;
