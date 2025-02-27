
WITH RankedPosts AS (
    SELECT 
        P.Id, 
        P.Title, 
        P.CreationDate, 
        P.Score, 
        U.DisplayName AS OwnerName, 
        COUNT(C.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        P.Id, U.DisplayName, P.Title, P.CreationDate, P.Score
),
PopularTags AS (
    SELECT 
        DISTINCT value AS Tag
    FROM 
        Posts T
    CROSS APPLY STRING_SPLIT(T.Tags, '><')
    WHERE 
        T.PostTypeId = 1
),
TagStatistics AS (
    SELECT 
        T.TagName, 
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' + '<' + T.TagName + '>%'
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
)
SELECT 
    RP.OwnerName, 
    RP.Title, 
    TAGS.TagName, 
    RP.CommentCount, 
    RP.Score,
    RP.CreationDate
FROM 
    RankedPosts RP
JOIN 
    TagStatistics TAGS ON RP.Title LIKE '%' + TAGS.TagName + '%'
WHERE 
    RP.PostRank <= 3
ORDER BY 
    RP.Score DESC, 
    RP.CommentCount DESC;
