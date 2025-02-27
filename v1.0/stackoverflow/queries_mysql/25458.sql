
WITH PostTags AS (
    SELECT 
        p.Id AS PostId, 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
         UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) 
         -CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
),
PopularTags AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagUsage
    FROM 
        PostTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalUpvotes DESC
    LIMIT 10
),
TagPostCounts AS (
    SELECT 
        pt.Tag, 
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        PostTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    GROUP BY 
        pt.Tag
    ORDER BY 
        PostCount DESC
)
SELECT 
    u.DisplayName AS TopUser, 
    u.TotalUpvotes, 
    u.TotalDownvotes, 
    tg.Tag, 
    tg.PostCount
FROM 
    TopUsers u
JOIN 
    TagPostCounts tg ON u.TotalPosts > 1 
WHERE 
    tg.Tag IN (SELECT Tag FROM PopularTags)
ORDER BY 
    u.TotalUpvotes DESC, 
    tg.PostCount DESC;
