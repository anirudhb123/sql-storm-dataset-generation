WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.Score > 0   -- Only questions with a positive score
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
),
TagPopularity AS (
    SELECT 
        TagName,
        COUNT(*) AS PopularityCount
    FROM 
        PopularTags
    GROUP BY 
        TagName
    ORDER BY 
        PopularityCount DESC
    LIMIT 10
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ph.UserDisplayName AS EditorDisplayName,
        PH.UserId
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
        AND ph.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    tp.TagName,
    tp.PopularityCount,
    re.EditDate,
    re.Comment,
    re.EditorDisplayName
FROM 
    RankedPosts rp
JOIN 
    TagPopularity tp ON EXISTS (
        SELECT 1 
        FROM UNNEST(string_to_array(substring(rp.Tags, 2, length(rp.Tags) - 2), '><')) AS tag 
        WHERE tag = tp.TagName
    )
LEFT JOIN 
    RecentEdits re ON rp.PostId = re.PostId
WHERE 
    rp.RankByScore <= 5  -- Top 5 ranked questions per tag
ORDER BY 
    tp.PopularityCount DESC, 
    rp.Score DESC;
