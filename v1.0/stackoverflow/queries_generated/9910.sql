WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
),

TopPostOwners AS (
    SELECT 
        Owner,
        COUNT(PostId) AS TotalPosts,
        SUM(Score) AS TotalScore,
        AVG(ViewCount) AS AvgViews
    FROM 
        RankedPosts
    GROUP BY 
        Owner
    HAVING 
        COUNT(PostId) > 10
),

PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(STRING_AGG(DISTINCT p.Tags, ','), ',')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)

SELECT 
    t.Tag,
    t.TagCount,
    o.Owner,
    o.TotalPosts,
    o.TotalScore,
    o.AvgViews
FROM 
    PopularTags t
JOIN 
    TopPostOwners o ON o.Owner IN (SELECT DISTINCT p.OwnerDisplayName FROM Posts p WHERE p.Tags LIKE '%' || t.Tag || '%')
ORDER BY 
    t.TagCount DESC, o.TotalScore DESC;
