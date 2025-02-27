WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY ARRAY(SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))) ORDER BY p.Score DESC) 
                           ORDER BY p.Score DESC) AS Rank,
        ARRAY(SELECT Name FROM PostHistoryTypes WHERE Id IN (
            SELECT PostHistoryTypeId 
            FROM PostHistory 
            WHERE PostId = p.Id
        )) AS RecentChanges
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND   -- Only considering questions
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Questions created in the last year
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Tags,
        rp.ViewCount,
        rp.Score,
        rp.Rank,
        rp.RecentChanges
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10  -- Top 10 ranked posts per tag
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Tags,
    fp.ViewCount,
    fp.Score,
    fp.RecentChanges,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation
FROM 
    FilteredPosts fp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC;  -- Final ordering by score and view count
