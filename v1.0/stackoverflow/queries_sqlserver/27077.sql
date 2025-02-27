
WITH TagOccurrences AS (
    SELECT 
        TRIM(STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '>')[1]) AS TagName, 
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(ISNULL(P.Score, 0)) AS TotalScore,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount
    FROM 
        Users AS U
    LEFT JOIN 
        Posts AS P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
), 
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagOccurrences
    WHERE 
        TagCount > 1 
),
ActivitySummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        AVG(DATEDIFF(SECOND, P.CreationDate, '2024-10-01 12:34:56')) AS AveragePostAgeInSeconds,
        AVG(DATEDIFF(SECOND, C.CreationDate, '2024-10-01 12:34:56')) AS AverageCommentAgeInSeconds
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.DisplayName,
    US.TotalScore,
    US.QuestionCount,
    US.AnswerCount,
    COALESCE(TT.TagName, 'No Tags') AS PopularTag,
    COALESCE(TT.TagCount, 0) AS TagCount,
    ASUM.TotalPosts,
    ASUM.TotalComments,
    ASUM.AveragePostAgeInSeconds,
    ASUM.AverageCommentAgeInSeconds
FROM 
    Users U
JOIN 
    UserScores US ON U.Id = US.UserId
LEFT JOIN 
    TopTags TT ON TT.Rank = 1  
JOIN 
    ActivitySummary ASUM ON ASUM.OwnerUserId = U.Id
ORDER BY 
    US.TotalScore DESC, 
    US.QuestionCount DESC;
