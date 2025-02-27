WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  -- Focus only on questions
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Questions created in the last year
),
TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagFrequency
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5  -- Only tags used more than 5 times
),
PopularTags AS (
    SELECT 
        tc.TagName,
        tc.TagFrequency,
        COUNT(*) AS PostCount,
        RANK() OVER (ORDER BY tc.TagFrequency DESC) AS FrequencyRank
    FROM 
        TagCounts tc
    JOIN 
        Posts p ON p.Tags LIKE '%' || tc.TagName || '%'
    GROUP BY 
        tc.TagName, tc.TagFrequency
)
SELECT 
    r.PostId,
    r.Title,
    r.ViewCount,
    r.OwnerDisplayName,
    p.TagName,
    p.TagFrequency,
    p.PostCount
FROM 
    RankedPosts r
JOIN 
    PopularTags p ON p.PostCount > 0
WHERE 
    r.ViewRank <= 10  -- Get top 10 viewed questions
ORDER BY 
    r.ViewCount DESC, 
    p.TagFrequency DESC;
