WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER(PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS RN,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER(PARTITION BY P.Id) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER(PARTITION BY P.Id) AS DownVoteCount,
        COALESCE(P.ClosedDate, P.LastActivityDate) AS LastRelevantActivity
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        MAX(P.LastActivityDate) AS LastActivity
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        MAX(P.LastActivityDate) >= NOW() - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.Comment AS CloseReason,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId, PH.Comment
),
PostSummary AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.Score,
        RP.UpVoteCount,
        RP.DownVoteCount,
        COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason,
        CASE 
            WHEN RP.RN = 1 THEN 'Latest' 
            ELSE 'Older' 
        END AS PostAgeClassification
    FROM 
        RankedPosts RP
    LEFT JOIN 
        ClosedPosts CP ON RP.PostId = CP.PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.OwnerDisplayName,
    PS.CreationDate,
    PS.Score,
    PS.UpVoteCount,
    PS.DownVoteCount,
    PS.CloseReason,
    AU.DisplayName AS ActiveUserDisplayName,
    AU.PostCount AS ActivePostCount,
    AU.LastActivity AS ActiveUserLastActivity,
    CASE 
        WHEN PS.LastRelevantActivity < NOW() - INTERVAL '6 months' THEN 'Inactive'
        ELSE 'Active'
    END AS PostActivityStatus
FROM 
    PostSummary PS
LEFT JOIN 
    ActiveUsers AU ON PS.OwnerDisplayName = AU.DisplayName
WHERE 
    (PS.CloseReason IS NOT NULL OR PS.Score > 0)
ORDER BY 
    PS.CreationDate DESC, 
    PS.Score DESC;
