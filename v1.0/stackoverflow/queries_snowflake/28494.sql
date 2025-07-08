
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS Author,
        P.CreationDate,
        P.Score,
        RANK() OVER (PARTITION BY P.Tags ORDER BY P.Score DESC) AS RankScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
        AND P.CreationDate >= '2023-01-01' 
),
TagStatistics AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P,
        LATERAL FLATTEN(INPUT => SPLIT(P.Tags, '>')) AS Tag
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        TagName
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        T.PostCount,
        T.AverageScore
    FROM 
        RankedPosts RP
    JOIN 
        TagStatistics T ON T.TagName IN (SELECT TRIM(value) FROM LATERAL FLATTEN(INPUT => SPLIT(RP.Tags, '>')))
    WHERE 
        RP.RankScore <= 5 
)

SELECT 
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.PostCount,
    TP.AverageScore,
    RP.CreationDate,
    LISTAGG(C.Text, '; ') AS Comments
FROM 
    TopPosts TP
LEFT JOIN 
    Comments C ON TP.PostId = C.PostId
LEFT JOIN 
    RankedPosts RP ON TP.PostId = RP.PostId
GROUP BY 
    TP.PostId, TP.Title, TP.Score, TP.PostCount, TP.AverageScore, RP.CreationDate
ORDER BY 
    TP.Score DESC, TP.PostCount DESC;
