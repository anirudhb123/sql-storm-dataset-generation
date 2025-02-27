WITH RecursivePosts AS (
    SELECT 
        Id,
        Title,
        ViewCount,
        Score,
        OwnerUserId,
        CreationDate,
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
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        p.CreationDate,
        p.ParentId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN RecursivePosts rp ON p.ParentId = rp.Id
),
PostVotes AS (
    SELECT
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId IN (6, 10) THEN 1 END) AS CloseVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        COALESCE(SUM(P.Score), 0) AS TotalPostScore,
        COALESCE(SUM(UP.Votes), 0) AS TotalUpVotes,
        COALESCE(SUM(DOWN.Votes), 0) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostVotes UP ON P.Id = UP.PostId
    LEFT JOIN 
        PostVotes DOWN ON P.Id = DOWN.PostId
    GROUP BY 
        U.Id
),
LatestPostHistory AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        P.Title,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS rn
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12)  -- Focus on Close/Reopen/Delete history
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPostScore,
    RP.Title AS RootPostTitle,
    RP.ViewCount AS RootPostViewCount,
    COALESCE(LPH.UserId, -1) AS LastUserId,
    COALESCE(LPH.CreationDate, NULL) AS LastHistoryDate,
    COALESCE(PV.UpVotes, 0) AS TotalUpVotes,
    COALESCE(PV.DownVotes, 0) AS TotalDownVotes,
    COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
    COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
FROM 
    UserStatistics U
JOIN 
    RecursivePosts RP ON U.UserId = RP.OwnerUserId
LEFT JOIN 
    LatestPostHistory LPH ON RP.Id = LPH.PostId AND LPH.rn = 1
LEFT JOIN 
    PostVotes PV ON RP.Id = PV.PostId
LEFT JOIN 
    PostHistory PH ON RP.Id = PH.PostId
GROUP BY 
    U.DisplayName, U.Reputation, U.TotalPostScore, RP.Title, RP.ViewCount, LPH.UserId, LPH.CreationDate, PV.UpVotes, PV.DownVotes
ORDER BY 
    U.Reputation DESC, ROOTPOSTVIEWCOUNT DESC
LIMIT 100;
