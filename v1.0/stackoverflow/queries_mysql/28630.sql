
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.Tags,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
),

TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        AVG(Score) AS AverageScore
    FROM 
        RecentPosts
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
        UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
        UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16
        UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    GROUP BY 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)
),

TopTags AS (
    SELECT 
        Tag,
        PostCount,
        PositiveScorePosts,
        AverageScore,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
)

SELECT 
    t.Tag,
    t.PostCount,
    t.PositiveScorePosts,
    t.AverageScore,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.OwnerDisplayName
FROM 
    TopTags t
JOIN 
    RecentPosts r ON r.Tags LIKE CONCAT('%', t.Tag, '%')
WHERE 
    t.TagRank <= 10
ORDER BY 
    t.TagRank, r.Score DESC;
