
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS TagName
    FROM 
        Posts p
    JOIN 
        (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) t, (SELECT @row := 0) r) n
    WHERE 
        p.PostTypeId = 1 AND 
        n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1
),
UserPostReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(IFNULL(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN p.Id END) AS AcceptedAnswers
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
    ORDER BY 
        TagUsage DESC
    LIMIT 10
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
