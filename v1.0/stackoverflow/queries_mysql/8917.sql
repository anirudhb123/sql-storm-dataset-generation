
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(a.AnswerCount, 0) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
),
TopTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1)) AS TagName
    FROM 
        RecentPosts
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
),
TagCounts AS (
    SELECT 
        TagName,
        COUNT(*) AS TagFrequency
    FROM 
        TopTags
    GROUP BY 
        TagName
    ORDER BY 
        TagFrequency DESC
    LIMIT 10
),
UserReputations AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS BadgeScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(COALESCE(b.Class, 0)) > 0
    ORDER BY 
        BadgeScore DESC
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RecentPosts rp
    JOIN 
        UserReputations ur ON rp.OwnerDisplayName = ur.DisplayName
    WHERE 
        ur.BadgeScore > 1
    ORDER BY 
        rp.Score DESC
    LIMIT 5
)
SELECT 
    pp.Title,
    pp.Score,
    pp.ViewCount,
    pp.OwnerDisplayName,
    tc.TagName
FROM 
    PopularPosts pp
JOIN 
    TagCounts tc ON pp.PostId IN (
        SELECT 
            PostId 
        FROM 
            Posts 
        WHERE 
            Tags LIKE CONCAT('%', tc.TagName, '%')
    )
ORDER BY 
    pp.Score DESC
LIMIT 5;
