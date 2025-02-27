
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        COUNT(A.Id) AS AnswerCount,
        P.CreationDate,
        RANK() OVER (PARTITION BY P.Tags ORDER BY P.CreationDate DESC) AS TagRank
    FROM 
        Posts P
        LEFT JOIN Comments C ON C.PostId = P.Id
        LEFT JOIN Posts A ON A.ParentId = P.Id
        JOIN Users U ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, P.Tags, U.DisplayName, P.CreationDate
),

TagPerformance AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CommentCount) AS TotalComments,
        SUM(AnswerCount) AS TotalAnswers,
        COUNT(DISTINCT OwnerDisplayName) AS UniqueAuthors,
        COUNT(*) * (CASE WHEN CreationDate > '2024-10-01 12:34:56' - INTERVAL 1 MONTH THEN 1 ELSE 0 END) AS RecentPosts
    FROM 
        RankedPosts
    JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    GROUP BY 
        Tag
)

SELECT 
    Tag,
    PostCount,
    TotalComments,
    TotalAnswers,
    UniqueAuthors,
    RecentPosts,
    ROUND((TotalComments / PostCount), 2) AS AvgCommentsPerPost,
    ROUND((TotalAnswers / PostCount), 2) AS AvgAnswersPerPost
FROM 
    TagPerformance
WHERE 
    PostCount > 10  
ORDER BY 
    RecentPosts DESC, AvgAnswersPerPost DESC;
