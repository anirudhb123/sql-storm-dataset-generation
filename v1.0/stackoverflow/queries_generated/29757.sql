WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
FrequentTaggers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT t.TagName) AS UniqueTagsCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS t(TagName) ON t.TagName IS NOT NULL
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT t.TagName) > 5
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        COALESCE(ft.UniqueTagsCount, 0) AS UniqueTagsCount,
        ur.TotalPosts,
        ur.TotalQuestions,
        ur.TotalAnswers,
        ur.TotalViews
    FROM 
        UserReputation ur
    LEFT JOIN 
        FrequentTaggers ft ON ur.UserId = ft.UserId
    ORDER BY 
        ur.Reputation DESC, ur.TotalViews DESC
    LIMIT 10
)
SELECT 
    bu.UserId,
    bu.DisplayName,
    bu.Reputation,
    bu.UniqueTagsCount,
    bu.TotalPosts,
    bu.TotalQuestions,
    bu.TotalAnswers,
    bu.TotalViews,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Posts p 
     JOIN LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS t(TagName) 
     ON p.OwnerUserId = bu.UserId) AS TagsUsed
FROM 
    TopUsers bu
ORDER BY 
    bu.Reputation DESC;
