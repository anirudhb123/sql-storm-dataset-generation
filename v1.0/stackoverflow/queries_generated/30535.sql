WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.ParentId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Start from Questions
    UNION ALL
    SELECT 
        P.Id,
        P.Title,
        P.OwnerUserId,
        P.ParentId,
        R.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy R ON P.ParentId = R.PostId
),
UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(SUM(PH.UserId IS NOT NULL), 0) AS EditCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS TotalUpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS TotalDownVotes,
        COUNT(CA.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments CA ON P.Id = CA.PostId
    GROUP BY 
        P.Id
),
RecentActivity AS (
    SELECT 
        P.Id AS PostId,
        P.CreationDate,
        P.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.LastActivityDate DESC) AS ActivityRank
    FROM 
        Posts P
)
SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    PS.EditCount,
    PS.TotalUpVotes,
    PS.TotalDownVotes,
    RA.RecentActivityDate,
    COUNT(DISTINCT RPH.PostId) AS AnswerCount,
    CASE 
        WHEN PS.EditCount > 0 THEN 'Edited' 
        ELSE 'Unedited' 
    END AS EditStatus,
    CASE 
        WHEN RA.LastActivityDate IS NULL THEN 'No recent activity' 
        ELSE CONCAT('Active since ', TO_CHAR(RA.LastActivityDate, 'YYYY-MM-DD HH24:MI:SS')) 
    END AS ActivityStatus
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
JOIN 
    PostActivity PS ON P.Id = PS.PostId
LEFT JOIN 
    RecursivePostHierarchy RPH ON P.Id = RPH.ParentId
LEFT JOIN 
    RecentActivity RA ON P.Id = RA.PostId AND RA.ActivityRank = 1
WHERE 
    PS.TotalUpVotes > 0 
    OR PS.TotalDownVotes > 0 
    OR PS.EditCount > 0
ORDER BY 
    PS.TotalUpVotes DESC, PS.TotalDownVotes ASC
FETCH FIRST 100 ROWS ONLY;
