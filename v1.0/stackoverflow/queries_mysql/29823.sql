
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        P.CreationDate,
        P.Score,
        U.DisplayName AS AuthorName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC, P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 
        AND P.CreationDate >= CURDATE() - INTERVAL 1 YEAR
    GROUP BY 
        P.Id, P.Title, P.Tags, P.CreationDate, P.Score, U.DisplayName
),

TagCount AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '>', numbers.n), '>', -1)) AS Tag,
        COUNT(*) AS TagFrequency
    FROM 
        Posts P
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '>', '')) >= numbers.n - 1
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '>', numbers.n), '>', -1))
    ORDER BY 
        TagFrequency DESC
    LIMIT 10
),

PopularAuthors AS (
    SELECT 
        U.DisplayName,
        SUM(P.Score) AS TotalScore,
        COUNT(P.Id) AS QuestionCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        U.DisplayName
    HAVING 
        COUNT(P.Id) > 10 
    ORDER BY 
        TotalScore DESC
    LIMIT 5
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.Tags,
    RP.CreationDate,
    RP.Score,
    RP.AuthorName,
    RP.CommentCount,
    TC.Tag AS TopTag,
    TC.TagFrequency,
    PA.DisplayName AS PopularAuthorName,
    PA.TotalScore AS PopularAuthorScore,
    PA.QuestionCount AS PopularAuthorQuestions
FROM 
    RankedPosts RP
LEFT JOIN 
    TagCount TC ON TC.Tag = RP.Tags
LEFT JOIN 
    PopularAuthors PA ON RP.AuthorName = PA.DisplayName
WHERE 
    RP.PostRank <= 3 
ORDER BY 
    RP.Score DESC, RP.CreationDate DESC;
