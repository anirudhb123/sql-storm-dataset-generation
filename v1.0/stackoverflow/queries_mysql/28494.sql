
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '>', n.n), '>', -1) AS TagName,
        COUNT(*) AS PostCount,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) n ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '>', '')) >= n.n - 1
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
        TagStatistics T ON FIND_IN_SET(T.TagName, REPLACE(RP.Tags, '>', ',')) > 0
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
    GROUP_CONCAT(C.Text SEPARATOR '; ') AS Comments
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
