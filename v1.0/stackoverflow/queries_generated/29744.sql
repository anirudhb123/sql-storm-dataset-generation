WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
),
TagStatistics AS (
    SELECT 
        TRIM(unnest(string_to_array(p.Tags, '>')) ) AS TagName,
        COUNT(*) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.ViewCount) AS AverageViews
    FROM 
        RankedPosts p
    WHERE 
        p.TagRank <= 5 -- Top 5 posts per tag
    GROUP BY 
        TagName
),
FrequentTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AverageViews,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagFrequencyRank
    FROM 
        TagStatistics
)
SELECT 
    f.TagName,
    f.PostCount,
    f.TotalViews,
    f.AverageViews,
    COALESCE(SUM(b.Class), 0) AS TotalBadgesEarned,
    STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
FROM 
    FrequentTags f
LEFT JOIN 
    Badges b ON f.TagName = TRIM(unnest(string_to_array(b.Name, ' '))) -- Assuming badge names might contain tag names
GROUP BY 
    f.TagName, 
    f.PostCount,
    f.TotalViews,
    f.AverageViews
ORDER BY 
    f.TagFrequencyRank;
