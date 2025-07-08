
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SPLIT(TRIM(BOTH '<>' FROM p.Tags), '><') AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS QuestionsWithAcceptedAnswers,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS HighViewQuestions,
        ARRAY_AGG(DISTINCT t.Tag) AS TagsUsed
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostTags t ON p.Id = t.PostId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        PostTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10  
),
UserTagActivity AS (
    SELECT 
        ua.UserId,
        value AS Tag,
        COUNT(*) AS TagUsageCount
    FROM 
        UserActivity ua,
        LATERAL FLATTEN(input => ua.TagsUsed) AS t
    WHERE 
        value IS NOT NULL
    GROUP BY 
        ua.UserId, Tag
)
SELECT 
    u.DisplayName,
    ua.TotalPosts,
    ua.TotalAnswers,
    ua.QuestionsWithAcceptedAnswers,
    ua.HighViewQuestions,
    LISTAGG(DISTINCT ut.Tag, ', ') AS MostUsedTags
FROM 
    UserActivity ua
JOIN 
    Users u ON ua.UserId = u.Id
LEFT JOIN 
    UserTagActivity ut ON u.Id = ut.UserId
WHERE 
    ua.TotalPosts > 5  
GROUP BY 
    u.DisplayName, ua.TotalPosts, ua.TotalAnswers, ua.QuestionsWithAcceptedAnswers, ua.HighViewQuestions
ORDER BY 
    ua.TotalPosts DESC, ua.TotalAnswers DESC;
