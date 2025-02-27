WITH ranked_posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Filtering for Questions
), 
tag_summary AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        TagName
),
recent_activity AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(CONCAT(h.CreationDate, ' by ', u.DisplayName, ': ', h.Comment), '; ') AS HistoryComments
    FROM 
        PostHistory h
    JOIN 
        Posts p ON h.PostId = p.Id
    JOIN 
        Users u ON h.UserId = u.Id
    WHERE 
        h.CreationDate > NOW() - INTERVAL '30 days' -- Recent edits
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    ts.PostCount,
    ra.HistoryComments
FROM 
    ranked_posts rp
LEFT JOIN 
    tag_summary ts ON rp.Tags ILIKE '%' || ts.TagName || '%' 
LEFT JOIN 
    recent_activity ra ON rp.PostId = ra.PostId
WHERE 
    rp.rn = 1 -- Get the latest post per tag
ORDER BY 
    rp.CreationDate DESC
LIMIT 10; -- Limit to 10 most recent questions per tag
