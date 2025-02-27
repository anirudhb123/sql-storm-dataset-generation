WITH RecursivePosts AS (
    SELECT 
        Id, 
        Title, 
        ParentId, 
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId, 
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.Id
),
UserDetails AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS BadgeCount,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id AND P.PostTypeId = 1) AS QuestionCount
    FROM 
        Users U
),
PostVoteSummary AS (
    SELECT 
        P.Id AS PostId, 
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
ClosedPosts AS (
    SELECT 
        P.Id, 
        P.Title, 
        P.CreationDate, 
        PH.UserId AS CloseUserId, 
        PH.CreationDate AS ClosedDate
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10  -- Closed posts
)
SELECT 
    U.DisplayName, 
    U.Reputation,
    UD.BadgeCount,
    P.Id AS PostId,
    P.Title AS PostTitle,
    CASE 
        WHEN CP.ClosedDate IS NOT NULL 
            THEN CONCAT('Closed on ', TO_CHAR(CP.ClosedDate, 'YYYY-MM-DD HH24:MI:SS')) 
        ELSE 'Open' 
    END AS PostStatus,
    PVS.UpVotes,
    PVS.DownVotes,
    RP.Level AS PostLevel  -- Level of post in hierarchy for nested comments
FROM 
    UserDetails UD
JOIN 
    Posts P ON P.OwnerUserId = UD.UserId
LEFT JOIN 
    ClosedPosts CP ON P.Id = CP.Id
LEFT JOIN 
    PostVoteSummary PVS ON P.Id = PVS.PostId
LEFT JOIN 
    RecursivePosts RP ON P.Id = RP.Id
WHERE 
    UD.Reputation > 1000  -- Filtering users with high reputation
ORDER BY 
    UD.Reputation DESC, P.CreationDate ASC
LIMIT 100;  -- Limiting the result for performance
