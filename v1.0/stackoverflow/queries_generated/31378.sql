WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND u.Reputation > 1000 -- Users with good reputation
),
RecentPosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5 -- Top 5 ranked posts by location
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    COALESCE(SUM(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
    COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount -- Upvotes
FROM 
    RecentPosts rp
LEFT JOIN 
    Comments c ON rp.Id = c.PostId
LEFT JOIN 
    Votes v ON rp.Id = v.PostId
WHERE 
    rp.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '30 days') -- Only recent posts
GROUP BY 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName
ORDER BY 
    rp.CreationDate DESC;
