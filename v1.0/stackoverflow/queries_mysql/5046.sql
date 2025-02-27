
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
        P.CreationDate >= NOW() - INTERVAL 30 DAY
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
    (SELECT GROUP_CONCAT(T.TagName SEPARATOR ', ') 
     FROM Tags T 
     JOIN (
         SELECT TRIM(TRAILING '>' FROM TRIM(LEADING '<' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1))) AS tag
         FROM (SELECT @row := @row + 1 AS n 
               FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers,
               (SELECT @row := 0) r) numbers
         WHERE @row < LENGTH(P.Tags) - LENGTH(REPLACE(P.Tags, '><', '')) + 1
     ) AS split_tags ON T.TagName = tag 
     WHERE P.Id = TP.PostId) AS TagsList
FROM 
    TopPosts TP
LEFT JOIN 
    Posts P ON TP.PostId = P.Id
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC;
