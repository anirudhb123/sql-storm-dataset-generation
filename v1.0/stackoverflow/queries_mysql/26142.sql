
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        @rownum := @rownum + 1 AS Rank
    FROM 
        TagCounts, (SELECT @rownum := 0) r
    ORDER BY 
        PostCount DESC
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentsMade,
        MAX(U.Reputation) AS Reputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostsCreated,
        AnswersGiven,
        QuestionsAsked,
        CommentsMade,
        Reputation,
        @activity_rank := @activity_rank + 1 AS ActivityRank
    FROM 
        UserActivity, (SELECT @activity_rank := 0) r
    WHERE 
        PostsCreated > 0
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        T.TagName
    FROM 
        ActiveUsers U
    JOIN 
        TopTags T ON U.QuestionsAsked = (SELECT MAX(QuestionsAsked) FROM ActiveUsers)
)
SELECT
    U.DisplayName AS TopUser,
    U.Reputation AS UserReputation,
    T.TagName AS MostPopularTag,
    COUNT(DISTINCT P.Id) AS QuestionsAsked,
    SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
FROM 
    TopUsers U
JOIN 
    Posts P ON U.UserId = P.OwnerUserId AND P.PostTypeId = 1  
JOIN 
    (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName
     FROM Posts 
     INNER JOIN (
         SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
     ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1) T ON T.TagName = TagName
GROUP BY 
    U.DisplayName, U.Reputation, T.TagName
ORDER BY 
    U.Reputation DESC, QuestionsAsked DESC;
