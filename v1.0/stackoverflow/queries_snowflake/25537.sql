
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
        COALESCE(MAX(b.Date), DATE '1970-01-01') AS LastBadgeDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags, u.DisplayName
),
PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        TRIM(value) AS Tag
    FROM 
        Posts p,
        TABLE(FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LEN(p.Tags) - 2), '><'))) AS t
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
        ARRAY_AGG(tp.Tag) AS PopularTags
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
