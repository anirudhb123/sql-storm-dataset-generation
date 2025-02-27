
WITH KeywordOccurrences AS (
    SELECT 
        P.Id AS PostId,
        COUNT(*) AS TagCount,
        SUM(CASE 
            WHEN P.Title LIKE '%SQL%' THEN 1 
            ELSE 0 END) AS SQLTitleCount,
        SUM(CASE 
            WHEN C.Text LIKE '%SQL%' THEN 1 
            ELSE 0 END) AS SQLCommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= CAST('2024-10-01' AS DATE) - DATEADD(YEAR, 1, 0)
    GROUP BY 
        P.Id
),
PostDetails AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        P.Title,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        K.TagCount,
        K.SQLTitleCount,
        K.SQLCommentCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        KeywordOccurrences K ON P.Id = K.PostId
    WHERE 
        P.PostTypeId = 1 
)
SELECT 
    DisplayName,
    Reputation,
    Title,
    ViewCount,
    AnswerCount,
    CommentCount,
    TagCount,
    SQLTitleCount,
    SQLCommentCount,
    CASE 
        WHEN SQLTitleCount > 0 THEN 'Contains SQL in Title' 
        ELSE 'No SQL in Title' 
    END AS TitleStatus,
    CASE 
        WHEN SQLCommentCount > 0 THEN 'Contains SQL in Comments' 
        ELSE 'No SQL in Comments' 
    END AS CommentStatus
FROM 
    PostDetails
ORDER BY 
    ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
