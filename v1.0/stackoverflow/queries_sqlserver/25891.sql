
WITH TagCounts AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '>') AS value
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        PostCount > 5  
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS QuestionCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(P.Id) > 3  
),
TagUserStatistics AS (
    SELECT 
        T.TagName,
        AU.UserId,
        AU.DisplayName,
        COUNT(DISTINCT P.Id) AS UserPostCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        TopTags T
    JOIN 
        Posts P ON P.Tags LIKE '%' + T.TagName + '%'
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        ActiveUsers AU ON AU.UserId = U.Id
    GROUP BY 
        T.TagName, AU.UserId, AU.DisplayName
),
FinalStatistics AS (
    SELECT 
        TagName,
        UserId,
        DisplayName,
        UserPostCount,
        AcceptedAnswers,
        RANK() OVER (PARTITION BY TagName ORDER BY UserPostCount DESC) AS UserRank
    FROM 
        TagUserStatistics
)
SELECT 
    F.TagName,
    F.DisplayName,
    F.UserPostCount,
    F.AcceptedAnswers,
    F.UserRank
FROM 
    FinalStatistics F
WHERE 
    F.UserRank <= 3  
ORDER BY 
    F.TagName, 
    F.UserRank;
