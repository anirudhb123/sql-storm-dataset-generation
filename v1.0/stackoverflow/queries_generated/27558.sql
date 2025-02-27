WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only include Questions
    GROUP BY 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><'))
),
UserReputation AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        COUNT(DISTINCT p.Id) AS QuestionsAnswered 
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 2 -- Answers
    GROUP BY 
        u.Id
),
TopTags AS (
    SELECT 
        TagName,
        PostCount
    FROM 
        TagCounts
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
UserActivity AS (
    SELECT 
        ur.UserId, 
        ur.DisplayName, 
        ur.Reputation,
        CONCAT('User has answered ', ur.QuestionsAnswered, ' questions.') AS Activity,
        tt.TagName
    FROM 
        UserReputation ur
    JOIN 
        Posts p ON ur.UserId = p.OwnerUserId
    JOIN 
        TopTags tt ON tt.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))
    ORDER BY 
        ur.Reputation DESC
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.Activity,
    ARRAY_AGG(DISTINCT ua.TagName) AS RelatedTags
FROM 
    UserActivity ua
GROUP BY 
    ua.UserId, ua.DisplayName, ua.Reputation, ua.Activity
HAVING 
    COUNT(DISTINCT ua.TagName) >= 3 -- Users who have interacted with at least 3 of the top tags
ORDER BY 
    ua.Reputation DESC;
