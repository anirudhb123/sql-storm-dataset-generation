
WITH TagCounts AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
    WHERE PostTypeId = 1 
    GROUP BY TRIM(value)
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM TagCounts
    WHERE PostCount > 5  
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
        RANK() OVER (PARTITION BY TT.TagName ORDER BY UR.Reputation DESC) AS UserRank
    FROM TopTags TT
    JOIN Posts P ON P.Tags LIKE '%' + TT.TagName + '%'
    JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN UserReputations UR ON U.Id = UR.UserId
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
