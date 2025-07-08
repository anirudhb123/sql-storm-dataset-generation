
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS Owner,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankByScore
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= CURRENT_TIMESTAMP() - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName, P.PostTypeId
),
TopPosts AS (
    SELECT 
        RP.PostId, 
        RP.Title, 
        RP.CreationDate, 
        RP.Score, 
        RP.ViewCount, 
        RP.Owner, 
        RP.CommentCount
    FROM 
        RankedPosts RP
    WHERE 
        RP.RankByScore <= 10
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.ViewCount,
    TP.Owner,
    TP.CommentCount,
    (SELECT LISTAGG(T.TagName, ', ') 
     FROM Tags T 
     JOIN LATERAL FLATTEN(INPUT => SPLIT(SUBSTRING(P.Tags, 2, LENGTH(P.Tags)-2), '><')) AS tag ON T.TagName = tag.VALUE 
     WHERE P.Id = TP.PostId) AS TagsList
FROM 
    TopPosts TP
LEFT JOIN 
    Posts P ON TP.PostId = P.Id
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;
