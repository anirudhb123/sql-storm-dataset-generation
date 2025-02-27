
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(c.Score, 0)) AS TotalComments,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        @rank := @rank + 1 AS Rank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    CROSS JOIN (SELECT @rank := 0) r
    GROUP BY u.Id, u.DisplayName
),
PopularTags AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM Posts p
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
    WHERE p.PostTypeId = 1 
    GROUP BY TagName
),
TopTags AS (
    SELECT TagName, TagCount,
           @tag_rank := @tag_rank + 1 AS TagRank
    FROM PopularTags, (SELECT @tag_rank := 0) r
    WHERE TagCount > 5
)
SELECT 
    ua.DisplayName,
    ua.TotalViews,
    ua.TotalComments,
    tt.TagName,
    tt.TagCount,
    CASE 
        WHEN ua.TotalPosts > 0 THEN (CAST(ua.TotalViews AS DECIMAL) / ua.TotalPosts) 
        ELSE NULL 
    END AS AvgViewsPerPost
FROM UserActivity ua
LEFT JOIN TopTags tt ON ua.UserId IN (
    SELECT DISTINCT p.OwnerUserId
    FROM Posts p
    WHERE p.Tags IS NOT NULL AND p.Tags LIKE CONCAT('%', tt.TagName, '%')
)
WHERE ua.Rank <= 10
ORDER BY ua.TotalViews DESC, tt.TagCount DESC;
