WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.ViewCount, p.Score
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5 -- Limit to Top 5 Tags
),
PostHistoryReports AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.CreationDate,
        p.OwnerUserId,
        PHType.Name AS ChangeType,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes PHType ON ph.PostHistoryTypeId = PHType.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 month' -- Changes in the last month
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    rp.TagsArray,
    COALESCE(pt.TagCount, 0) AS PopularTagCount,
    phr.UserDisplayName AS LastEditedBy,
    phr.ChangeType,
    phr.Comment AS ChangeComment,
    phr.CreationDate AS ChangeDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.TagsArray @> ARRAY[pt.TagName] -- Check for popular tags
LEFT JOIN 
    PostHistoryReports phr ON rp.PostId = phr.PostId
WHERE 
    rp.PostRank <= 3 -- Top 3 posts per user
ORDER BY 
    rp.OwnerDisplayName, 
    rp.Score DESC;
