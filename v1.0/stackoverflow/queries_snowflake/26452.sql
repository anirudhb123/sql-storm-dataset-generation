
WITH TagCounts AS (
    SELECT 
        TRIM(SPLIT_PART(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><', seq)) AS TagName,
        COUNT(*) AS TagUsage
    FROM 
        Posts,
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) seq
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(SPLIT_PART(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><', seq))
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
