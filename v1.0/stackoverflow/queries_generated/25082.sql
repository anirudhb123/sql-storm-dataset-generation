WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),

TagList AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
),

BioLength AS (
    SELECT 
        u.Id AS UserId,
        LENGTH(u.AboutMe) AS BioLength
    FROM 
        Users u
)

SELECT 
    u.DisplayName,
    ua.TotalQuestions,
    ua.TotalComments,
    ua.TotalViews,
    COALESCE(bl.BioLength, 0) AS BioLength,
    string_agg(DISTINCT tl.TagName, ', ') AS TagsUsed,
    COUNT(DISTINCT rp.PostId) AS RecentQuestionsCount
FROM 
    Users u
JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    BioLength bl ON u.Id = bl.UserId
LEFT JOIN 
    TagList tl ON tl.PostId IN (SELECT PostId FROM RankedPosts WHERE Rank <= 5)
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
GROUP BY 
    u.Id, ua.TotalQuestions, ua.TotalComments, ua.TotalViews, bl.BioLength
ORDER BY 
    ua.TotalViews DESC, ua.TotalQuestions DESC;
