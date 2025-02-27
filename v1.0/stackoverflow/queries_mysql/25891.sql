
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM 
        TagCounts, (SELECT @rank := 0) r
    WHERE 
        PostCount > 5  
    ORDER BY 
        PostCount DESC
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
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
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
        @user_rank := IF(@prev_tag = TagName, @user_rank + 1, 1) AS UserRank,
        @prev_tag := TagName
    FROM 
        TagUserStatistics, (SELECT @user_rank := 0, @prev_tag := '') r
    ORDER BY 
        TagName, UserPostCount DESC
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
