WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Only counting upvotes and downvotes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.*,
        pt.Name AS PostTypeName,
        u.DisplayName AS OwnerDisplayName
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.Rank = 1 AND rp.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = pt.Id) 
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    VoteCount,
    PostTypeName,
    OwnerDisplayName
FROM 
    TopPosts
WHERE 
    VoteCount > 0
ORDER BY 
    CreationDate DESC
LIMIT 10;
