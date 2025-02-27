WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(b.Reputation, 0) AS OwnerReputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName, b.Reputation
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerDisplayName,
        OwnerReputation,
        CommentCount,
        AnswerCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    tp.CommentCount,
    tp.AnswerCount,
    pt.Name AS PostType,
    COALESCE(pht.Name, 'N/A') AS PostHistoryType
FROM 
    TopPosts tp
LEFT JOIN 
    PostTypes pt ON tp.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = pt.Id)
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
ORDER BY 
    tp.Score DESC;
