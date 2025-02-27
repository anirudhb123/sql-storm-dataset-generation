WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),

AggregatedData AS (
    SELECT 
        t.TagName,
        COUNT(rp.PostId) AS PostCount,
        AVG(rp.ViewCount) AS AvgViews,
        AVG(rp.Score) AS AvgScore,
        STRING_AGG(DISTINCT rp.Title, '; ') AS RecentPostTitles,
        STRING_AGG(DISTINCT rp.Body, '; ') AS RecentPostBodies
    FROM 
        RankedPosts rp
    JOIN 
        Tags t ON rp.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        rp.rn <= 5 -- Limit to the 5 most recent posts per tag
    GROUP BY 
        t.TagName
),

TopTags AS (
    SELECT 
        TagName,
        PostCount,
        AvgViews,
        AvgScore,
        RecentPostTitles,
        RecentPostBodies,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        AggregatedData
)

SELECT 
    TagName,
    PostCount,
    AvgViews,
    AvgScore,
    RecentPostTitles,
    RecentPostBodies
FROM 
    TopTags
WHERE 
    Rank <= 10 -- Top 10 tags by post count
ORDER BY 
    PostCount DESC;

-- This query benchmarked string processing capabilities by utilizing 
-- STRING_AGG to concatenate post titles and bodies for the most 
-- common tags, providing insights into post engagement trends.
