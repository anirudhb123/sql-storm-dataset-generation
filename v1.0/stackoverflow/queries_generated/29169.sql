WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COALESCE(ph.Comment, 'No changes') AS LastEditComment,
        ph.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags edits
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
), FilteredPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.EditRank = 1  -- Selecting most recent edit
        AND (rp.LastEditDate > CURRENT_DATE - INTERVAL '90 days')  -- Edited within the last 90 days
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.Score,
    fp.ViewCount,
    fp.LastEditComment,
    fp.LastEditDate,
    COUNT(c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalUpvotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    Comments c ON fp.PostId = c.PostId
LEFT JOIN 
    Votes v ON fp.PostId = v.PostId AND v.VoteTypeId = 2  -- Upvotes
LEFT JOIN 
    UNNEST(string_to_array(fp.Body, '<tag>')) AS t(TagName)  -- Assume tags are embedded in the Body
GROUP BY 
    fp.PostId, fp.Title, fp.Body, fp.CreationDate, fp.OwnerDisplayName, fp.Score, fp.ViewCount, fp.LastEditComment, fp.LastEditDate
ORDER BY 
    fp.Score DESC, 
    fp.LastEditDate DESC
LIMIT 100;
