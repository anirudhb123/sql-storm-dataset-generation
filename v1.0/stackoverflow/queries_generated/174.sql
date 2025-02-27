WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.ViewCount, 
        P.Score, 
        P.OwnerUserId, 
        R.ReputationRank
    FROM 
        Posts P
    JOIN 
        RankedUsers R ON P.OwnerUserId = R.UserId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
PostStats AS (
    SELECT 
        RP.*, 
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = RP.PostId AND V.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = RP.PostId AND V.VoteTypeId = 3), 0) AS DownVoteCount,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = RP.PostId), 0) AS CommentCount
    FROM 
        RecentPosts RP
)
SELECT 
    PS.PostId, 
    PS.Title, 
    PS.ViewCount, 
    PS.Score, 
    PS.UpVoteCount, 
    PS.DownVoteCount, 
    PS.CommentCount,
    R.DisplayName AS OwnerName,
    PS.ReputationRank
FROM 
    PostStats PS
LEFT JOIN 
    Users R ON PS.OwnerUserId = R.Id
WHERE 
    PS.CommentCount > 0
ORDER BY 
    PS.Score DESC, 
    PS.ViewCount DESC;

WITH PostHistoryCounts AS (
    SELECT 
        PH.PostId, 
        COUNT(*) AS EditCount, 
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    P.Title, 
    PH.EditCount, 
    PH.CloseCount
FROM 
    Posts P
JOIN 
    PostHistoryCounts PH ON P.Id = PH.PostId
WHERE 
    P.AcceptedAnswerId IS NOT NULL
    AND PH.EditCount > 5
ORDER BY 
    PH.CloseCount DESC;

SELECT 
    'Total Closed Posts' AS Metric, 
    COUNT(DISTINCT P.Id) AS TotalCount
FROM 
    Posts P
JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    PH.PostHistoryTypeId = 10;

SELECT 
    T.TagName, 
    COUNT(DISTINCT P.Id) AS PostCount
FROM 
    Tags T
JOIN 
    Posts P ON T.Id = ANY(STRING_TO_ARRAY(P.Tags, '><')::int[])
WHERE 
    P.CreationDate >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY 
    T.TagName
HAVING 
    COUNT(DISTINCT P.Id) > 3 
ORDER BY 
    PostCount DESC;
