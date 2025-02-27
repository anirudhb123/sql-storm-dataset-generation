
WITH TagCounts AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1 
    WHERE PostTypeId = 1 
    GROUP BY TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1))
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM TagCounts, (SELECT @rank := 0) r
    WHERE PostCount > 5  
    ORDER BY PostCount DESC
),
UserReputations AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT A.Id) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    LEFT JOIN Posts A ON U.Id = A.OwnerUserId AND A.PostTypeId = 2 
    GROUP BY U.Id, U.Reputation
),
TagAnalysis AS (
    SELECT 
        TT.TagName,
        UR.UserId,
        UR.Reputation,
        UR.QuestionCount,
        UR.AnswerCount,
        @user_rank := IF(@current_tag = TT.TagName, @user_rank + 1, 1) AS UserRank,
        @current_tag := TT.TagName
    FROM TopTags TT
    JOIN Posts P ON P.Tags LIKE CONCAT('%', TT.TagName, '%')
    JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN UserReputations UR ON U.Id = UR.UserId,
    (SELECT @user_rank := 0, @current_tag := '') r
    WHERE UR.QuestionCount > 0 
)
SELECT 
    TA.TagName,
    TA.UserId,
    U.DisplayName,
    TA.Reputation,
    TA.QuestionCount,
    TA.AnswerCount,
    TA.UserRank
FROM TagAnalysis TA
JOIN Users U ON TA.UserId = U.Id
WHERE TA.UserRank <= 5 
ORDER BY TA.TagName, TA.UserRank;
