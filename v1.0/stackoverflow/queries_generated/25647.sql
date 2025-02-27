WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagPopularityRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Only recent questions
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.ViewCount,
        rp.Score,
        rp.Owner,
        rp.TagPopularityRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagPopularityRank <= 5 -- Top 5 posts per tag
),
TaggedPostStats AS (
    SELECT 
        t.TagName,
        COUNT(tp.PostId) AS PostCount,
        AVG(tp.ViewCount) AS AvgViews,
        AVG(tp.Score) AS AvgScore
    FROM 
        Tags t
    LEFT JOIN 
        TopPosts tp ON tp.Tags LIKE '%' || t.TagName || '%' -- Join with top posts
    GROUP BY 
        t.TagName
)
SELECT 
    t.TagName,
    ts.PostCount,
    ts.AvgViews,
    ts.AvgScore,
    CONCAT(ROUND(ts.AvgScore::numeric, 2), ' / 5') AS FormattedAvgScore
FROM 
    TaggedPostStats ts
JOIN 
    Tags t ON ts.TagName = t.TagName
ORDER BY 
    ts.PostCount DESC, -- Order by number of posts
    ts.AvgViews DESC; -- Then by average views
