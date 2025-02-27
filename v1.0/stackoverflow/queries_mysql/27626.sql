
WITH StringStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        CHAR_LENGTH(P.Body) AS BodyLength,
        CHAR_LENGTH(P.Title) AS TitleLength,
        (SELECT COUNT(*) FROM (
            SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1)) AS tag
            FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
            WHERE numbers.n <= 1 + (LENGTH(P.Tags) - LENGTH(REPLACE(P.Tags, '><', '')))
        ) AS tags) AS TagCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName
),
StringPerformance AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerDisplayName,
        BodyLength,
        TitleLength,
        TagCount,
        CommentCount,
        VoteCount,
        CASE 
            WHEN BodyLength > 2000 THEN 'Long Body'
            WHEN BodyLength BETWEEN 1000 AND 2000 THEN 'Medium Body'
            ELSE 'Short Body'
        END AS BodySizeCategory,
        CASE 
            WHEN TitleLength > 100 THEN 'Long Title'
            ELSE 'Short Title'
        END AS TitleSizeCategory
    FROM 
        StringStats
)
SELECT 
    BodySizeCategory,
    TitleSizeCategory,
    COUNT(*) AS PostCount,
    AVG(CommentCount) AS AvgComments,
    AVG(VoteCount) AS AvgVotes
FROM 
    StringPerformance
GROUP BY 
    BodySizeCategory, TitleSizeCategory
ORDER BY 
    BodySizeCategory, TitleSizeCategory;
