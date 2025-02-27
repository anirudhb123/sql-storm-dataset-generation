WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    r.PostId,
    r.Title,
    r.ViewCount,
    r.Score,
    r.OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
    COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
    pt.Name AS PostType, 
    pt.Id AS PostTypeId
FROM 
    RankedPosts r
LEFT JOIN 
    Comments c ON r.PostId = c.PostId
LEFT JOIN 
    Votes v ON r.PostId = v.PostId
JOIN 
    PostTypes pt ON r.PostTypeId = pt.Id
WHERE 
    r.Rank <= 5
GROUP BY 
    r.PostId, r.Title, r.ViewCount, r.Score, r.OwnerDisplayName, pt.Name, pt.Id
ORDER BY 
    r.Score DESC, r.ViewCount DESC;
