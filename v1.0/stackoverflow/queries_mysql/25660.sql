
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
        P.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
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
        V.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
    GROUP BY
        V.PostId
),
PopularTags AS (
    SELECT
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1)) AS Tag,
        COUNT(*) AS TagCount
    FROM
        Posts P
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
    WHERE
        P.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
    GROUP BY
        Tag
    ORDER BY
        TagCount DESC
    LIMIT 10
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
