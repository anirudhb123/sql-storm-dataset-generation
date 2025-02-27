
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(MAX(b.Date), '1970-01-01') AS LastBadgeDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags, u.DisplayName
),
PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.Tags IS NOT NULL
),
TagPopularity AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        PostTagCounts 
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostBenchmarks AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerDisplayName,
        pd.Score,
        pd.ViewCount,
        pd.CommentCount,
        pd.LastBadgeDate,
        GROUP_CONCAT(tp.Tag) AS PopularTags
    FROM 
        PostDetails pd
    JOIN 
        PostTagCounts pt ON pd.PostId = pt.PostId
    JOIN 
        TagPopularity tp ON pt.Tag = tp.Tag
    GROUP BY 
        pd.PostId, pd.Title, pd.OwnerDisplayName, pd.Score, pd.ViewCount, pd.CommentCount, pd.LastBadgeDate
)
SELECT
    pb.PostId,
    pb.Title,
    pb.OwnerDisplayName,
    pb.Score,
    pb.ViewCount,
    pb.CommentCount,
    pb.LastBadgeDate,
    pb.PopularTags,
    CASE 
        WHEN pb.ViewCount > 1000 THEN 'High Visibility'
        WHEN pb.ViewCount BETWEEN 500 AND 1000 THEN 'Moderate Visibility'
        ELSE 'Low Visibility'
    END AS VisibilityCategory,
    CASE 
        WHEN pb.CommentCount > 50 THEN 'Highly Engaged'
        WHEN pb.CommentCount BETWEEN 20 AND 50 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostBenchmarks pb
ORDER BY 
    pb.Score DESC, pb.ViewCount DESC;
