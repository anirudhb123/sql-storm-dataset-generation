WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvotes only
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, u.DisplayName
    ORDER BY 
        p.CreationDate DESC
    LIMIT 100
),
PostDetails AS (
    SELECT 
        rp.*,
        COALESCE((
            SELECT STRING_AGG(t.TagName, ', ') 
            FROM Tags t 
            WHERE t.Id IN (SELECT unnest(string_to_array(p.Tags, ','::text)::int[])) 
        ), 'No Tags') AS Tags
    FROM 
        RankedPosts rp
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.VoteCount,
    pd.Tags
FROM 
    PostDetails pd
JOIN 
    PostHistory ph ON pd.PostId = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) -- Filter for closed and reopened posts
WHERE 
    ph.CreationDate > NOW() - INTERVAL '1 month'
ORDER BY 
    pd.Score DESC, pd.CommentCount DESC;
