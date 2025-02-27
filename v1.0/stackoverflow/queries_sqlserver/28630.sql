
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
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '30 days'
),
TagStatistics AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        AVG(Score) AS AverageScore
    FROM 
        RecentPosts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS t
    GROUP BY 
        value
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
    RecentPosts r ON r.Tags LIKE '%' + t.Tag + '%'
WHERE 
    t.TagRank <= 10
ORDER BY 
    t.TagRank, r.Score DESC;
