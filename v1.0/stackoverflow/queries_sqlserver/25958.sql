
WITH TagUsage AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS UsageCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
),
MostPopularTags AS (
    SELECT 
        TagName, 
        UsageCount
    FROM 
        TagUsage
    ORDER BY 
        UsageCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
UserResponses AS (
    SELECT 
        p.OwnerUserId,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN a.ParentId IS NOT NULL THEN 1 ELSE 0 END) AS ParentAnswers,
        SUM(CASE WHEN a.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(DATEDIFF(SECOND, p.CreationDate, a.CreationDate) / 3600.0) AS AvgResponseTime
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
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
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
