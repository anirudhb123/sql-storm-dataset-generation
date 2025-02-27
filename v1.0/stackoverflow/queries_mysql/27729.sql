
WITH TagFrequency AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TagDetails AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        TF.PostCount
    FROM 
        Tags T
    JOIN 
        TagFrequency TF ON T.TagName = TF.Tag
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS QuestionCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
MostPopularTags AS (
    SELECT 
        TagId,
        TagName,
        PostCount,
        @rownum := @rownum + 1 AS PopularityRank
    FROM 
        TagDetails, (SELECT @rownum := 0) r
    ORDER BY 
        PostCount DESC
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        QuestionCount,
        AcceptedAnswerCount,
        @rownum2 := @rownum2 + 1 AS ReputationRank
    FROM 
        UserReputation, (SELECT @rownum2 := 0) r
    ORDER BY 
        Reputation DESC
)
SELECT 
    MT.TagName AS MostPopularTag,
    U.DisplayName AS TopUser,
    U.Reputation AS UserReputation,
    U.QuestionCount AS UserQuestionCount,
    U.AcceptedAnswerCount AS UserAcceptedAnswers,
    MT.PostCount AS TagPostCount
FROM 
    MostPopularTags MT
JOIN 
    TopUsers U ON MT.PopularityRank <= 10 AND U.ReputationRank <= 10
ORDER BY 
    MT.PostCount DESC, U.Reputation DESC;
