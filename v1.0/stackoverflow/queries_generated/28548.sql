WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(t.TagName, ', ') AS TagsList,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))::int)
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS UsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))::int)
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY 
        t.TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 10
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        p.Title,
        p.Body,
        p.OwnerDisplayName,
        p.LastEditorDisplayName,
        ph.Comment AS PostEditComment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
        AND ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.TagsList,
    rp.CommentCount,
    pt.UsageCount AS PopularTagUsage,
    rph.OwnerDisplayName,
    rph.LastEditorDisplayName,
    rph.PostEditComment
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.TagsList LIKE '%' || pt.TagName || '%'
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId
WHERE 
    rp.ScoreRank <= 5  -- Limit to top 5 posts by score in each post type
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
