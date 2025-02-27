WITH TagStats AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagStats
    WHERE 
        TagCount > 5 -- Filtering for tags used more than 5 times
),
PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        TopTags t ON t.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))
)
SELECT 
    pi.PostId,
    pi.Title,
    pi.CreationDate,
    pi.OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(ph.Id) AS HistoryChangeCount,
    STRING_AGG(DISTINCT tt.TagName, ', ') AS TagsUsed
FROM 
    PostInfo pi
LEFT JOIN 
    Comments c ON c.PostId = pi.PostId
LEFT JOIN 
    PostHistory ph ON ph.PostId = pi.PostId AND ph.CreationDate > CURRENT_DATE - INTERVAL '30 days' -- Changes in the last 30 days
GROUP BY 
    pi.PostId, pi.Title, pi.CreationDate, pi.OwnerDisplayName
ORDER BY 
    CommentCount DESC, HistoryChangeCount DESC
LIMIT 10;
