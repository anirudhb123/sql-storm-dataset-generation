
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN (
        SELECT 
            1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
            SELECT 9 UNION ALL SELECT 10
    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
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
        TopTags tt ON FIND_IN_SET(tt.TagName, TRIM(BOTH '<>' FROM Tags)) > 0
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.Activity,
    GROUP_CONCAT(DISTINCT ua.TagName) AS RelatedTags
FROM 
    UserActivity ua
GROUP BY 
    ua.UserId, ua.DisplayName, ua.Reputation, ua.Activity
HAVING 
    COUNT(DISTINCT ua.TagName) >= 3 
ORDER BY 
    ua.Reputation DESC;
