WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY u.Reputation ORDER BY p.Score DESC) AS RankByReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Filtering for Questions only
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Only posts from the last year
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByReputation <= 5 -- Top 5 posts per reputation tier
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.Score,
    t.ViewCount,
    t.OwnerDisplayName,
    t.CommentCount,
    COALESCE((SELECT STRING_AGG(Tag.TagName, ', ') 
               FROM Tags Tag 
               WHERE Tag.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int))
              ), 'No Tags') AS Tags
FROM 
    TopPosts t
JOIN 
    Posts p ON t.PostId = p.Id
ORDER BY 
    t.CreationDate DESC;
