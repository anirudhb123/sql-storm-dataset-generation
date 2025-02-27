WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, Score, CreationDate, OwnerDisplayName, CommentCount, VoteCount
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 10
)
SELECT 
    t.PostId,
    t.Title,
    t.Score,
    t.CreationDate,
    t.OwnerDisplayName,
    t.CommentCount,
    t.VoteCount,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    COUNT(DISTINCT ph.Id) AS EditHistoryCount
FROM 
    TopPosts t
LEFT JOIN 
    Badges b ON t.OwnerDisplayName = b.UserId
LEFT JOIN 
    PostHistory ph ON t.PostId = ph.PostId
GROUP BY 
    t.PostId, t.Title, t.Score, t.CreationDate, t.OwnerDisplayName, b.Name
ORDER BY 
    t.Score DESC, t.CreationDate DESC;
