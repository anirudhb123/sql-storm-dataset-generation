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
        P.ParentId IS NULL
    
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
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COALESCE(SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostVoteCounts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        P.Id, P.Title
),
PostsWithHistory AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastHistoryDate,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        COALESCE(PH.LastHistoryDate, '1900-01-01') AS LastActionDate
    FROM 
        Posts P
    LEFT JOIN 
        PostsWithHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
)

SELECT 
    PS.PostId,
    PS.Title,
    U.DisplayName AS Author,
    COALESCE(PV.TotalVotes, 0) AS TotalVotes,
    ASC.PostCount AS AnswerCount,
    R.Level AS HierarchyLevel,
    PH.HistoryTypes,
    U.BadgeCount,
    U.UpVotesCount - U.DownVotesCount AS UserVoteBalance,
    CASE 
        WHEN U.Reputation > 1000 THEN 'Expert'
        WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    ActivePosts PS
LEFT JOIN 
    UserStats U ON PS.OwnerUserId = U.UserId
LEFT JOIN 
    PostVoteCounts PV ON PS.PostId = PV.PostId
LEFT JOIN 
    RecursivePostHierarchy R ON PS.PostId = R.PostId
LEFT JOIN 
    PostsWithHistory PH ON PS.PostId = PH.PostId
LEFT JOIN 
    (SELECT 
        ParentId,
        COUNT(*) AS PostCount
     FROM 
        Posts 
     WHERE 
        PostTypeId = 2
     GROUP BY 
        ParentId) ASC ON PS.PostId = ASC.ParentId
WHERE 
    PS.LastActionDate IS NOT NULL
ORDER BY 
    PS.Title ASC,
    UserVoteBalance DESC,
    ActivePosts.LastActionDate DESC;
