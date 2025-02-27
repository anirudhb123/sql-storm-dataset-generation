WITH TagUsage AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS UsageCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only consider Questions
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        UsageCount,
        ROW_NUMBER() OVER (ORDER BY UsageCount DESC) AS Rank
    FROM 
        TagUsage
    WHERE 
        UsageCount > 5 -- Filter for tags used more than 5 times
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalQuestions,
        TotalAnswers,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
    WHERE 
        Reputation > 50  -- Filter for users with reputation greater than 50
)
SELECT 
    T.Tag,
    T.UsageCount,
    U.DisplayName AS TopUser,
    U.Reputation AS UserReputation,
    U.TotalQuestions AS QuestionCount,
    U.TotalAnswers AS AnswerCount
FROM 
    TopTags T
JOIN 
    TopUsers U ON T.Rank = (SELECT MIN(Rank) FROM TopUsers U2 WHERE U2.TotalQuestions > 10) 
ORDER BY 
    T.UsageCount DESC;
