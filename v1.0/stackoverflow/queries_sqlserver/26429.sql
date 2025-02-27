
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        LTRIM(RTRIM(value)) AS TagName
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS value
    WHERE 
        p.PostTypeId = 1  
),
UserPostReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(ISNULL(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT p.Id) AS AcceptedAnswers
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
),
TopTags AS (
    SELECT 
        pt.TagName,
        COUNT(pt.PostId) AS TagUsage
    FROM 
        PostTags pt
    GROUP BY 
        pt.TagName
)

SELECT 
    u.DisplayName,
    u.Reputation,
    upr.TotalScore,
    upr.PostCount,
    upr.AcceptedAnswers,
    tt.TagName,
    tt.TagUsage
FROM 
    UserPostReputation upr
CROSS JOIN 
    TopTags tt
JOIN 
    Users u ON u.Id = upr.UserId
WHERE 
    upr.PostCount > 5 
ORDER BY 
    upr.Reputation DESC,
    tt.TagUsage DESC;
