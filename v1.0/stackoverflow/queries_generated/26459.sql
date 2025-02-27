WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '90 days' -- Last 90 days
),
TopTags AS (
    SELECT 
        Tags,
        COUNT(*) AS PostCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 -- Top 5 posts per tag
    GROUP BY 
        Tags
    ORDER BY 
        PostCount DESC
    LIMIT 10 -- Top 10 tags by post count
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (4, 5, 24)) AS EditCount -- Title and body edits
    FROM 
        PostHistory ph
    JOIN 
        RankedPosts rp ON ph.PostId = rp.PostId
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    th.PostCount,
    pha.LastEditDate,
    pha.EditCount
FROM 
    RankedPosts rp
JOIN 
    TopTags th ON rp.Tags = th.Tags
JOIN 
    PostHistoryAggregated pha ON rp.PostId = pha.PostId
WHERE 
    rp.Rank <= 5 -- Ensuring we have the top 5 for each tag
ORDER BY 
    th.PostCount DESC, rp.Score DESC;
