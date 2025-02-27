WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),

PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Answered' 
            ELSE 'Unanswered' 
        END AS Status,
        COALESCE(SUM(CASE WHEN C.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.AcceptedAnswerId
),

ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS rn
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11)  -- Closed or Reopened
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.UpVotes,
    U.DownVotes,
    U.PostCount,
    P.PostId,
    P.Title,
    P.Status,
    P.CommentCount,
    COALESCE(CP.CloseReason, 'Not Closed') AS LastCloseReason
FROM 
    UserVoteSummary U
LEFT JOIN 
    PostSummary P ON U.UserId = P.PostId -- Assuming relation based on IDs, can change based on your requirements
LEFT JOIN 
    ClosedPostHistory CP ON P.PostId = CP.PostId AND CP.rn = 1
WHERE 
    U.PostCount > 0
    AND (U.UpVotes - U.DownVotes) > 5
ORDER BY 
    U.Reputation DESC, P.CommentCount DESC
LIMIT 50;

-- Optional: Union with another query to showcase different conditions or scenarios
UNION ALL 

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    0 AS UpVotes,
    0 AS DownVotes,
    COUNT(P.Id) AS PostCount,
    NULL AS PostId,
    NULL AS Title,
    'Unable to retrieve' AS Status,
    0 AS CommentCount,
    'No Comments' AS LastCloseReason
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
WHERE 
    U.Reputation < 10
GROUP BY 
    U.Id, U.DisplayName
HAVING 
    COUNT(P.Id) = 0
ORDER BY 
    U.DisplayName;

This SQL query performs a multi-step aggregation process using CTEs to summarize user voting behavior and relevant post information. It includes various constructs such as left joins, window functions for calculating ranks, and complex predicates, as well as a UNION to demonstrate different sections of the data. The last subquery opts for users with low reputation and post count to illustrate contrasting data retrieval.
