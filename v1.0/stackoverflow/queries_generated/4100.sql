WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RankByUser
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Filtering for Questions only
        AND P.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        RP.*,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation,
        U.Location,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = RP.PostId) AS CommentCount
    FROM 
        RankedPosts RP
    JOIN 
        Users U ON RP.OwnerUserId = U.Id
    WHERE 
        RP.RankByUser = 1
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.Score,
    COALESCE(TP.ViewCount, 0) AS ViewCount,
    TP.OwnerDisplayName,
    TP.Reputation,
    NULLIF(TP.Location, '') AS UserLocation,
    TP.CommentCount,
    CASE 
        WHEN TP.Reputation >= 1000 THEN 'High Reputation User'
        ELSE 'Regular User'
    END AS UserType,
    COALESCE((
        SELECT STRING_AGG(Tag.TagName, ', ')
        FROM Tags Tag
        WHERE Tag.Id IN (SELECT UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><'))::int[])
        LIMIT 5
    ), 'No Tags') AS Tags
FROM 
    TopPosts TP
ORDER BY 
    TP.Score DESC,
    TP.CreationDate DESC
LIMIT 10;

-- Benchmarking for complex retrieval and aggregation with potential high-volume data
SELECT 
    PH.PostId,
    PH.CreationDate,
    PHT.Name AS HistoryType,
    PH.UserId,
    PH.UserDisplayName,
    COUNT(*) OVER (PARTITION BY PH.PostId) AS EditCount
FROM 
    PostHistory PH
JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
WHERE 
    PH.CreationDate >= NOW() - INTERVAL '6 months'
    AND PHT.Name IN ('Edit Body', 'Edit Title')
ORDER BY 
    PH.CreationDate DESC;

-- Subquery testing for the number of votes per post, outer join to capture unmatched posts
SELECT 
    P.Title,
    COUNT(V.Id) AS VoteCount
FROM 
    Posts P
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.PostTypeId = 1
GROUP BY 
    P.Title
HAVING 
    COUNT(V.Id) > 5
ORDER BY 
    VoteCount DESC;
