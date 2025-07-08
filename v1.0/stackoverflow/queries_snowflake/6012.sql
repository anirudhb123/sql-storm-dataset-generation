
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostTypeName
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days' 
        AND p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, pt.Name
),
TopPostsByType AS (
    SELECT 
        Rank, 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        CommentCount, 
        VoteCount, 
        OwnerDisplayName,
        PostTypeName
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 5
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.Score,
    t.ViewCount,
    t.CommentCount,
    t.VoteCount,
    t.OwnerDisplayName,
    t.PostTypeName AS PostType
FROM 
    TopPostsByType t
JOIN 
    PostTypes pt ON t.PostTypeName = pt.Name
ORDER BY 
    pt.Name, t.Score DESC;
