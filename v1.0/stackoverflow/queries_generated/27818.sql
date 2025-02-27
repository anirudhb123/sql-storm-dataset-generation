WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
),
TopTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagUsage
    FROM 
        PostTags
    GROUP BY 
        Tag
    ORDER BY 
        TagUsage DESC
    LIMIT 5
),
UserActivity AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        t.Tag,
        SUM(ur.QuestionCount) AS TotalQuestions,
        SUM(ur.CommentCount) AS TotalComments
    FROM 
        UserReputation ur
    JOIN 
        PostTags pt ON pt.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ur.UserId)
    JOIN 
        TopTags t ON t.Tag = pt.Tag
    GROUP BY 
        ur.UserId, ur.Reputation, t.Tag
),
FinalOutput AS (
    SELECT 
        ua.UserId,
        u.DisplayName,
        ua.Tag,
        ua.Reputation,
        ua.TotalQuestions,
        ua.TotalComments
    FROM 
        UserActivity ua
    JOIN 
        Users u ON ua.UserId = u.Id
    ORDER BY 
        ua.Reputation DESC, ua.TotalQuestions DESC
)

SELECT 
    *
FROM 
    FinalOutput
WHERE 
    TotalQuestions > 0
ORDER BY 
    Reputation DESC, TotalComments DESC;
