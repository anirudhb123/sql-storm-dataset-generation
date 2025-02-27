WITH TagCounts AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1 -- Only questions
    GROUP BY TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM TagCounts
    WHERE PostCount > 5  -- Filter for tags with more than 5 questions
),
UserReputations AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT A.Id) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 -- Questions
    LEFT JOIN Posts A ON U.Id = A.OwnerUserId AND A.PostTypeId = 2 -- Answers
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
    JOIN Posts P ON P.Tags LIKE '%<%>' || TT.TagName || '%<%>'  -- Check if the Post has the Tag
    JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN UserReputations UR ON U.Id = UR.UserId
    WHERE UR.QuestionCount > 0 -- Only consider users with questions
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
WHERE TA.UserRank <= 5 -- Get top 5 users for each tag
ORDER BY TA.TagName, TA.UserRank;
