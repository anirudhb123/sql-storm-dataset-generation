WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        OwnerDisplayName, 
        CommentCount, 
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 10
)
SELECT 
    tp.*,
    pt.Name AS PostTypeName,
    btc.Name AS BadgeName,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     WHERE t.Id IN (SELECT unnest(string_to_array(p.Tags, ', '))::int)) AS AssociatedTags
FROM 
    TopPosts tp
LEFT JOIN 
    PostTypes pt ON tp.PostTypeId = pt.Id
LEFT JOIN 
    Badges b ON tp.PostId = b.UserId
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId 
WHERE 
    b.Class = 1 OR b.Class = 2
ORDER BY 
    tp.CreationDate DESC;
