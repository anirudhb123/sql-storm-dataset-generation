
WITH PostTagCounts AS (
    SELECT 
        post.Id AS PostId, 
        SUBSTRING_INDEX(SUBSTRING_INDEX(post.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts post
    JOIN 
        (SELECT a.N + b.N * 10 + 1 AS n
         FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS b) numbers ON CHAR_LENGTH(post.Tags) - CHAR_LENGTH(REPLACE(post.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        post.PostTypeId = 1
),
TagAggregates AS (
    SELECT 
        Tag, 
        COUNT(*) AS PostCount
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5
),
UserPostCounts AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS UserPostCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        up.UserPostCount
    FROM 
        Users u
    JOIN 
        UserPostCounts up ON u.Id = up.OwnerUserId
    WHERE 
        u.LastAccessDate > NOW() - INTERVAL 1 YEAR
),
TopPostTags AS (
    SELECT 
        t.Tag, 
        SUM(up.UserPostCount) AS TotalPosts
    FROM 
        TagAggregates t
    JOIN 
        PostTagCounts pt ON t.Tag = pt.Tag
    JOIN 
        UserPostCounts up ON pt.PostId = up.OwnerUserId
    GROUP BY 
        t.Tag
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
)
SELECT 
    u.DisplayName, 
    u.Reputation, 
    t.Tag,
    t.TotalPosts
FROM 
    ActiveUsers u
JOIN 
    TopPostTags t ON u.UserPostCount > 10
ORDER BY 
    u.Reputation DESC, t.TotalPosts DESC;
