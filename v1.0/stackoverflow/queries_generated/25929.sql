WITH RecentEdits AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(ph.Comment) AS EditComments
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.ViewCount,
        COALESCE(r.EditCount, 0) AS RecentEditCount,
        r.LastEditDate,
        r.EditComments
    FROM 
        Posts p
    LEFT JOIN 
        RecentEdits r ON p.Id = r.PostId
    WHERE 
        p.ViewCount > 1000
)
SELECT 
    tp.Title,
    tp.Body,
    tp.ViewCount,
    tp.RecentEditCount,
    tp.LastEditDate,
    tp.EditComments,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
LEFT JOIN 
    STRING_TO_ARRAY(tp.Tags, ',') AS tag_array ON 
    EXISTS (SELECT 1 FROM Tags t WHERE t.TagName IN (tag_array))
LEFT JOIN 
    Tags t ON t.TagName IN (SELECT UNNEST(tag_array))
GROUP BY 
    tp.Title, tp.Body, tp.ViewCount, tp.RecentEditCount, tp.LastEditDate, tp.EditComments, u.DisplayName, u.Reputation
ORDER BY 
    tp.ViewCount DESC, tp.RecentEditCount DESC
LIMIT 
    10;
