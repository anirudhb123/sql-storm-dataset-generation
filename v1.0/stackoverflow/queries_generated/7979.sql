WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Count only upvotes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerName,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    t.Title,
    t.OwnerName,
    t.CreationDate,
    t.Score,
    t.CommentCount,
    t.VoteCount,
    pt.Name AS PostType
FROM 
    TopPosts t
JOIN 
    PostTypes pt ON t.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = pt.Id)
ORDER BY 
    t.Score DESC, t.CreationDate DESC;
