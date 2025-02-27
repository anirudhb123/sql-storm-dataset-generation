WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, '<>'))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostHistorySummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        MAX(ph.CreationDate) AS LastEditDate,
        ARRAY_AGG(DISTINCT ph.UserDisplayName) AS Editors
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) -- Title and Body edits
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Rank,
    rp.OwnerDisplayName,
    rp.CommentCount,
    pts.LastEditDate,
    pts.Editors,
    pt.TagName
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistorySummary pts ON rp.PostId = pts.PostId
LEFT JOIN 
    PopularTags pt ON pt.TagName = ANY(ARRAY(SELECT TRIM(UNNEST(string_to_array(rp.Title, '<>'))) AS TagName)) 
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
