WITH TagCounts AS (
    SELECT 
        tag.TagName, 
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags AS tag
    LEFT JOIN 
        Posts AS p ON p.Tags LIKE '%' || tag.TagName || '%'
    GROUP BY 
        tag.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users AS u
    LEFT JOIN 
        Posts AS p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopTags AS (
    SELECT 
        TagName,
        PostCount, 
        (PostCount * 1.0 / NULLIF((SELECT SUM(PostCount) FROM TagCounts), 0)) AS PercentageOfTotalPosts
    FROM 
        TagCounts
    ORDER BY 
        PostCount DESC 
    LIMIT 10
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        AnswerCount, 
        AcceptedAnswers,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
    WHERE 
        PostCount > 0
)

SELECT 
    t.TagName,
    t.PostCount,
    t.PercentageOfTotalPosts,
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.PostCount AS UserPostCount,
    u.AnswerCount,
    u.AcceptedAnswers,
    u.ReputationRank
FROM 
    TopTags AS t
JOIN 
    Posts AS p ON p.Tags LIKE '%' || t.TagName || '%'
JOIN 
    UserReputation AS u ON p.OwnerUserId = u.UserId
WHERE 
    u.ReputationRank <= 5
ORDER BY 
    t.PostCount DESC, 
    u.Reputation DESC;
