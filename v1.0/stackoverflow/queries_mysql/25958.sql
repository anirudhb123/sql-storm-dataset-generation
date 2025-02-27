
WITH TagUsage AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS UsageCount
    FROM 
        Posts
    JOIN 
        (SELECT @row := @row + 1 AS n FROM 
            (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) t1,
            (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) t2,
            (SELECT @row := 0) t0) n 
        ON LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),
MostPopularTags AS (
    SELECT 
        TagName, 
        UsageCount
    FROM 
        TagUsage
    ORDER BY 
        UsageCount DESC
    LIMIT 10
),
UserResponses AS (
    SELECT 
        p.OwnerUserId,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN a.ParentId IS NOT NULL THEN 1 ELSE 0 END) AS ParentAnswers,
        SUM(CASE WHEN a.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(TIMESTAMPDIFF(SECOND, p.CreationDate, a.CreationDate) / 3600.0) AS AvgResponseTime
    FROM 
        Posts p
    JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ur.AnswerCount,
        ur.ParentAnswers,
        ur.AcceptedAnswers,
        ur.AvgResponseTime
    FROM 
        Users u
    JOIN 
        UserResponses ur ON u.Id = ur.OwnerUserId
    WHERE 
        u.Reputation > 1000 
    ORDER BY 
        ur.AcceptedAnswers DESC, ur.AnswerCount DESC
    LIMIT 5
)
SELECT 
    t.TagName,
    t.UsageCount,
    u.DisplayName,
    u.Reputation,
    u.AnswerCount,
    u.ParentAnswers,
    u.AcceptedAnswers,
    u.AvgResponseTime
FROM 
    MostPopularTags t
JOIN 
    TopUsers u ON u.AcceptedAnswers > 0
ORDER BY 
    t.UsageCount DESC, 
    u.AcceptedAnswers DESC;
