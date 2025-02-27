
WITH TagCounts AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS TagUsage
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
         UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) 
         -CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n-1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1))
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COUNT(DISTINCT b.Id) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveTags AS (
    SELECT 
        tc.TagName,
        tc.TagUsage,
        ur.UserId,
        ur.DisplayName,
        ur.TotalReputation,
        ur.PostsCount,
        ur.CommentsCount,
        ur.BadgesCount
    FROM 
        TagCounts tc
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', tc.TagName, '%')
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        UserReputation ur ON u.Id = ur.UserId
    WHERE 
        tc.TagUsage > 10 
)
SELECT 
    at.TagName,
    at.TagUsage,
    COUNT(DISTINCT at.UserId) AS UniqueUsers,
    AVG(at.TotalReputation) AS AvgReputation,
    AVG(at.PostsCount) AS AvgPosts,
    AVG(at.CommentsCount) AS AvgComments,
    AVG(at.BadgesCount) AS AvgBadges
FROM 
    ActiveTags at
GROUP BY 
    at.TagName, at.TagUsage
ORDER BY 
    at.TagUsage DESC;
