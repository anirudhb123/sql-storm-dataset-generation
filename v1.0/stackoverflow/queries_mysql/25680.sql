
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM Posts
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE PostTypeId = 1  
    GROUP BY Tag
), 
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        @row_number := @row_number + 1 AS TagRank
    FROM TagCounts, (SELECT @row_number := 0) r
    WHERE PostCount > 5  
    ORDER BY PostCount DESC
),
MostRecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerName,
        pt.Name AS PostType
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 MONTH) 
)
SELECT 
    t.Tag,
    t.PostCount AS TagPopularity,
    p.Title AS RecentPostTitle,
    p.OwnerName AS RecentPostOwner,
    p.CreationDate AS RecentPostDate,
    p.PostType AS RecentPostType
FROM TopTags t
LEFT JOIN MostRecentPosts p ON t.Tag LIKE CONCAT('%', p.Tags, '%')  
ORDER BY t.PostCount DESC, p.CreationDate DESC;
