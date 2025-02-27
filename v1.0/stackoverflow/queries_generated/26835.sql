WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
), PopularTags AS (
    SELECT 
        t.TagName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
        JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        TotalViews DESC
    LIMIT 10
), PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
        JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '1 year'  -- Last year edits
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Owner,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    pht.HistoryTypes,
    pht.EditCount,
    pt.TagName AS PopularTag,
    pt.TotalViews,
    pt.PostCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryInfo pht ON rp.PostId = pht.PostId
JOIN 
    PopularTags pt ON pt.TagName = ANY(STRING_TO_ARRAY(rp.Tags, ','))
WHERE 
    rp.rn = 1  -- Ensure we take the latest posts only
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
