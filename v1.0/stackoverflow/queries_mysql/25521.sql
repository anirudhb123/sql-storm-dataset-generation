
WITH TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        GROUP_CONCAT(DISTINCT u.DisplayName ORDER BY u.DisplayName ASC SEPARATOR ', ') AS ActiveUsers,
        AVG(p.Score) AS AverageScore
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE t.Count > 0
    GROUP BY t.TagName
),
UsersWithTopTags AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT t.Id) AS TagCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
        FROM Posts p 
        INNER JOIN (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
            SELECT 9 UNION ALL SELECT 10
        ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    ) AS tag ON true
    LEFT JOIN Tags t ON t.TagName = tag.TagName
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(DISTINCT t.Id) >= 3 
),
BenchmarkResult AS (
    SELECT
        ts.TagName,
        ts.PostCount,
        ts.TotalViews,
        ts.TotalAnswers,
        ts.AverageScore,
        u.DisplayName AS UserWithMostPosts
    FROM TagStatistics ts
    LEFT JOIN (
        SELECT 
            p.Tags,
            p.OwnerUserId,
            COUNT(*) AS UserPostCount 
        FROM Posts p
        WHERE p.Tags IS NOT NULL
        GROUP BY p.Tags, p.OwnerUserId
    ) user_post_count ON user_post_count.Tags = ts.TagName
    JOIN Users u ON u.Id = user_post_count.OwnerUserId
    ORDER BY ts.TotalViews DESC
    LIMIT 10
)
SELECT 
    b.TagName,
    b.PostCount,
    b.TotalViews,
    b.TotalAnswers,
    b.AverageScore,
    COALESCE(b.UserWithMostPosts, 'No Posts') AS UserWithMostPosts
FROM BenchmarkResult b;
