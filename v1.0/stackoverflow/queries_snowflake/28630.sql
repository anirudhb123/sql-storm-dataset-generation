
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
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 DAY'
),

TagStatistics AS (
    SELECT 
        TRIM(value) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        AVG(Score) AS AverageScore
    FROM 
        RecentPosts,
        LATERAL SPLIT_TO_TABLE(Tags, '><')  -- use SPLIT_TO_TABLE to split tags
    GROUP BY 
        TRIM(value)
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
    RecentPosts r ON r.Tags ILIKE '%' || t.Tag || '%'
WHERE 
    t.TagRank <= 10
ORDER BY 
    t.TagRank, r.Score DESC;
