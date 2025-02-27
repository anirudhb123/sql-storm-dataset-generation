WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        LastAccessDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        Users
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostHistoryAnalytics AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS ChangesCount,
        MIN(PH.CreationDate) AS FirstDate,
        MAX(PH.CreationDate) AS LastDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    UR.Reputation,
    RP.PostId,
    RP.Title,
    RP.CreationDate AS PostCreationDate,
    PVC.UpVotes,
    PVC.DownVotes,
    PH.AnalysisChanges AS HistoryChangeCount,
    COALESCE(PH.FirstDate, 'No Changes') AS FirstChangeDate,
    COALESCE(PH.LastDate, 'No Changes') AS LastChangeDate,
    CASE 
        WHEN UR.Reputation > 1000 THEN 'High'
        WHEN UR.Reputation BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS ReputationCategory
FROM 
    Users U
LEFT JOIN 
    UserReputation UR ON U.Id = UR.Id
JOIN 
    RecentPosts RP ON U.Id = RP.OwnerUserId
LEFT JOIN 
    PostVoteCounts PVC ON RP.PostId = PVC.PostId
LEFT JOIN 
    PostHistoryAnalytics PH ON RP.PostId = PH.PostId
WHERE 
    U.LastAccessDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    UR.Rank, RP.PostCreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
