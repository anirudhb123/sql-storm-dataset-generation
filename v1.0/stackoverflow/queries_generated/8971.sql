WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.ViewCount > 1000
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    t.PostId,
    t.Title,
    t.Score,
    t.OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
    ARRAY_AGG(DISTINCT b.Name) AS BadgeNames
FROM 
    TopPosts t
LEFT JOIN 
    Comments c ON c.PostId = t.PostId
LEFT JOIN 
    Votes v ON v.PostId = t.PostId
LEFT JOIN 
    Badges b ON b.UserId = t.OwnerUserId
GROUP BY 
    t.PostId, t.Title, t.Score, t.OwnerDisplayName
ORDER BY 
    t.Score DESC, t.CreationDate DESC;
