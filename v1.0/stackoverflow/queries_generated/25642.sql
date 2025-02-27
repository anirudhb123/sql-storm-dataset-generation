WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags) - 2), '><') AS tagArray ON true
    JOIN 
        Tags t ON t.TagName = tagArray
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, pt.Name
),

TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body, 
        rp.ViewCount, 
        rp.Score, 
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.ViewCount,
    tp.Score,
    tp.Tags,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    u.Location AS OwnerLocation
FROM 
    TopPosts tp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
ORDER BY 
    tp.Score DESC;

This query benchmarks string processing through a step-wise aggregation of posts. It ranks posts by type and creation date while aggregating the distinct tags associated with each post. The final selection retrieves the top 5 posts of each type from the past year, including user information, sorted by score, demonstrating both string manipulation and ranking logic.
