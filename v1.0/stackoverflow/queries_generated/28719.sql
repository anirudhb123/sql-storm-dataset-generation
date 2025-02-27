WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- We only want questions
        AND p.Score > 0 -- Filtering for questions with at least one score
),
TagStatistics AS (
    SELECT 
        UNNEST(string_to_array(LEFT(Tags, LENGTH(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(ph.UserDisplayName) AS LastEditedBy
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) -- Edit Title, Edit Body, Edit Tags, Suggested Edit Applied
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    ts.TagName,
    ts.TagCount,
    re.EditCount,
    re.LastEditDate,
    re.LastEditedBy
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON rp.Tags LIKE '%' || ts.TagName || '%'
LEFT JOIN 
    RecentEdits re ON rp.PostId = re.PostId
WHERE 
    rp.PostRank <= 5 -- Get top 5 posts for each user
ORDER BY 
    rp.OwnerDisplayName, rp.Score DESC;
