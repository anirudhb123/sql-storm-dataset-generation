
WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        P.CreationDate,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS RN
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    WHERE
        P.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '30 days'
    GROUP BY
        P.Id, P.Title, P.Body, P.Tags, P.CreationDate, P.Score
),
RankedVotes AS (
    SELECT
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM
        Votes V
    WHERE
        V.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '30 days'
    GROUP BY
        V.PostId
),
PopularTags AS (
    SELECT
        TRIM(value) AS Tag,
        COUNT(*) AS TagCount
    FROM
        Posts P
    CROSS APPLY STRING_SPLIT(P.Tags, '><') 
    WHERE
        P.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '30 days'
    GROUP BY
        TRIM(value)
    ORDER BY
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.Tags,
    RP.CreationDate,
    RP.Score,
    RV.UpVotes,
    RV.DownVotes,
    RV.TotalVotes,
    PT.Tag AS PopularTag,
    PT.TagCount
FROM
    RankedPosts RP
LEFT JOIN
    RankedVotes RV ON RP.PostId = RV.PostId
CROSS JOIN
    PopularTags PT
WHERE
    RP.RN = 1  
ORDER BY
    RP.Score DESC,
    RV.TotalVotes DESC;
