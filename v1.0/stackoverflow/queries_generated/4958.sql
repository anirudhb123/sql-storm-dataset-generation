WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostMetrics AS (
    SELECT 
        RP.Id,
        RP.Title,
        RP.OwnerDisplayName,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(AVG(PH.CreationDate), 0) AS AvgPostHistoryDate,
        RP.Score,
        RP.ViewCount,
        RP.AnswerCount,
        RP.PostRank
    FROM 
        RankedPosts RP
    LEFT JOIN 
        Comments C ON RP.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON RP.Id = PH.PostId
    GROUP BY 
        RP.Id, RP.Title, RP.OwnerDisplayName, RP.Score, RP.ViewCount, RP.AnswerCount, RP.PostRank
)
SELECT 
    PM.Title,
    PM.OwnerDisplayName,
    PM.Score,
    PM.ViewCount,
    PM.CommentCount,
    PM.AvgPostHistoryDate,
    CASE 
        WHEN PM.PostRank <= 3 THEN 'Top Post' 
        WHEN PM.PostRank BETWEEN 4 AND 10 THEN 'Popular Post' 
        ELSE 'Other' 
    END AS PostCategory
FROM 
    PostMetrics PM
WHERE 
    PM.Score > 10
ORDER BY 
    PM.Score DESC, PM.ViewCount DESC
LIMIT 50
UNION ALL
SELECT 
    DISTINCT P.Title,
    U.DisplayName AS OwnerDisplayName,
    P.Score,
    P.ViewCount,
    0 AS CommentCount,
    NULL AS AvgPostHistoryDate,
    'Orphaned Post' AS PostCategory
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.Id NOT IN (SELECT DISTINCT C.PostId FROM Comments C)
    AND P.CreationDate < NOW() - INTERVAL '2 years'
ORDER BY 
    P.Score DESC
LIMIT 20;
