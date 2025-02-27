WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.OwnerUserId,
        U.Reputation,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.ViewCount > 0 AND P.AcceptedAnswerId IS NOT NULL
),
RecentVotes AS (
    SELECT 
        V.PostId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        V.PostId
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        MAX(PH.CreationDate) AS LastHistoryDate,
        CASE 
            WHEN PH.PostHistoryTypeId IN (10, 11) THEN JSON_AGG(CAST(PH.Comment AS VARCHAR))
            ELSE NULL 
        END AS CloseReasons
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.CreationDate AS PostCreationDate,
    U.DisplayName AS OwnerDisplayName,
    RP.Reputation,
    COALESCE(RV.TotalVotes, 0) AS TotalVotes,
    COALESCE(RV.UpVotes, 0) AS UpVotes,
    COALESCE(RV.DownVotes, 0) AS DownVotes,
    COALESCE(PHD.LastHistoryDate, '1970-01-01') AS LastHistoryDate,
    PHD.CloseReasons
FROM 
    RankedPosts RP
LEFT JOIN 
    Users U ON RP.OwnerUserId = U.Id
LEFT JOIN 
    RecentVotes RV ON RP.PostId = RV.PostId
LEFT JOIN 
    PostHistoryDetails PHD ON RP.PostId = PHD.PostId
WHERE 
    RP.PostRank = 1
ORDER BY 
    RP.ViewCount DESC, RP.CreationDate ASC
LIMIT 10;
