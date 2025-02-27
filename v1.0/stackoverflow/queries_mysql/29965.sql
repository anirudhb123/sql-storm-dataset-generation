
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
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
        GROUP_CONCAT(DISTINCT t.Tag SEPARATOR ', ') AS TagsUsed
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
        pt.Tag,
        COUNT(*) AS TagUsageCount
    FROM 
        UserActivity ua
    JOIN 
        PostTags pt ON ua.UserId = pt.UserId -- Adjusting JOIN based on available data
    GROUP BY 
        ua.UserId, pt.Tag
)
SELECT 
    u.DisplayName,
    ua.TotalPosts,
    ua.TotalAnswers,
    ua.QuestionsWithAcceptedAnswers,
    ua.HighViewQuestions,
    GROUP_CONCAT(DISTINCT ut.Tag SEPARATOR ', ') AS MostUsedTags
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
