WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        TagName
),

TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        PostCount > 10 -- Filtering tags with more than 10 questions
),

UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 END), 0) AS AcceptedAnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),

TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.QuestionCount,
        U.AnswerCount,
        U.AcceptedAnswerCount,
        RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        UserStats U
    WHERE 
        U.QuestionCount > 5 -- Only considering users with more than 5 questions
)

SELECT 
    TU.DisplayName AS TopUser,
    TU.Reputation AS UserReputation,
    TT.TagName,
    TT.PostCount AS NumberOfPostsWithTag,
    COUNT(CASE WHEN P.OwnerUserId = TU.UserId THEN 1 END) AS UserPostsCount
FROM 
    TopTags TT
JOIN 
    PostLinks PL ON TT.TagName = (SELECT TagName FROM Tags WHERE Id = PL.RelatedPostId)
JOIN 
    Posts P ON P.Id = PL.PostId
JOIN 
    TopUsers TU ON P.OwnerUserId = TU.UserId
GROUP BY 
    TU.DisplayName, TU.Reputation, TT.TagName, TT.PostCount
HAVING 
    COUNT(CASE WHEN P.OwnerUserId = TU.UserId THEN 1 END) > 0 -- Ensure the user has posts linked
ORDER BY 
    UserReputation DESC, PostCount DESC;
