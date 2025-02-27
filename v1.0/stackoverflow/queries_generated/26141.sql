WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
), 
TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
), 
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        TagCount > 5 -- Filter for tags used in more than 5 questions
), 
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    tt.TagName,
    rp.OwnerDisplayName,
    rp.Reputation,
    ph.UserDisplayName AS Editor,
    ph.Comment AS EditComment,
    ph.HistoryDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId AND ph.HistoryRank = 1  -- Most recent edit
JOIN 
    (SELECT * FROM TopTags LIMIT 10) tt ON rp.Tags LIKE '%' || tt.TagName || '%'  -- Limit to top 10 tags
WHERE 
    rp.PostRank = 1  -- Only most recent post from each user
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;  -- Order by score and view count
