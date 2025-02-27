
WITH TagCounts AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionsAnswered 
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 2 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopTags AS (
    SELECT 
        TagName,
        PostCount
    FROM 
        TagCounts
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
UserActivity AS (
    SELECT 
        ur.UserId, 
        ur.DisplayName, 
        ur.Reputation,
        'User has answered ' + CAST(ur.QuestionsAnswered AS NVARCHAR(10)) + ' questions.' AS Activity,
        tt.TagName
    FROM 
        UserReputation ur
    JOIN 
        Posts p ON ur.UserId = p.OwnerUserId
    JOIN 
        TopTags tt ON tt.TagName IN (SELECT value FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><'))
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.Activity,
    STRING_AGG(DISTINCT ua.TagName, ', ') AS RelatedTags
FROM 
    UserActivity ua
GROUP BY 
    ua.UserId, ua.DisplayName, ua.Reputation, ua.Activity
HAVING 
    COUNT(DISTINCT ua.TagName) >= 3 
ORDER BY 
    ua.Reputation DESC;
