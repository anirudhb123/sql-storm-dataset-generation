WITH TagsList AS (
    SELECT 
        Id AS TagId,
        TagName,
        COUNT(*) AS TagUsageCount,
        STRING_AGG(DISTINCT CONCAT('Post ID: ', PostId), ', ') AS RelatedPosts
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS Tag
    GROUP BY 
        Id, TagName
),
TopTags AS (
    SELECT 
        TagId,
        TagName,
        TagUsageCount,
        RelatedPosts
    FROM 
        TagsList
    WHERE 
        TagUsageCount > 5 -- More than 5 uses to consider as significantly used
    ORDER BY 
        TagUsageCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
UsersEngaged AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostCount
    FROM 
        Users u
    JOIN 
        Comments c ON c.UserId = u.Id
    JOIN 
        Posts p ON c.PostId = p.Id
    WHERE 
        u.Reputation > 1000 -- Engaged users with significant reputation
    GROUP BY 
        u.Id, u.DisplayName
),
PopularUserEngagement AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.CommentCount,
        ue.PopularPostCount,
        t.TagName
    FROM 
        UsersEngaged ue
    JOIN 
        Posts p ON p.OwnerUserId = ue.UserId
    JOIN 
        TagsList t ON (t.RelatedPosts LIKE '%' + CAST(p.Id AS VARCHAR) + '%')
    WHERE 
        ue.PopularPostCount > 0
)
SELECT 
    PUE.DisplayName,
    COUNT(DISTINCT PUE.TagName) AS EngagedTagCount,
    SUM(PUE.CommentCount) AS TotalComments,
    SUM(PUE.PopularPostCount) AS TotalPopularPosts
FROM 
    PopularUserEngagement PUE
GROUP BY 
    PUE.DisplayName
ORDER BY 
    TotalComments DESC;
