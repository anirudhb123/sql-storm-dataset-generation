WITH TitleWordCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(word) AS TitleWordCount
    FROM 
        Posts p,
        LATERAL string_to_array(p.Title, ' ') AS word
    GROUP BY 
        p.Id
),
BodyWordCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(word) AS BodyWordCount
    FROM 
        Posts p,
        LATERAL string_to_array(p.Body, ' ') AS word
    GROUP BY 
        p.Id
),
TagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(tag) AS TagCount
    FROM 
        Posts p,
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><') AS tag
    WHERE 
        p.PostTypeId = 1 -- Only for Questions
    GROUP BY 
        p.Id
),
UserPostDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(tc.TagCount, 0) AS TagCount,
        COALESCE(twc.TitleWordCount, 0) AS TitleWordCount,
        COALESCE(bwc.BodyWordCount, 0) AS BodyWordCount,
        COUNT(p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        TagCounts tc ON tc.PostId = p.Id
    LEFT JOIN 
        TitleWordCounts twc ON twc.PostId = p.Id
    LEFT JOIN 
        BodyWordCounts bwc ON bwc.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName, tc.TagCount, twc.TitleWordCount, bwc.BodyWordCount
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    SUM(u.TitleWordCount) AS TotalTitleWords,
    SUM(u.BodyWordCount) AS TotalBodyWords,
    SUM(u.TagCount) AS TotalTags
FROM 
    UserPostDetails u
GROUP BY 
    u.DisplayName, u.TotalPosts
ORDER BY 
    TotalTitleWords DESC, TotalBodyWords DESC, TotalTags DESC;
