WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Only questions
),
MostActiveUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 10
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score, 
        rp.AnswerCount, 
        rp.CommentCount, 
        rp.OwnerDisplayName,
        ma.PostCount
    FROM 
        RankedPosts rp
    JOIN 
        MostActiveUsers ma ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ma.OwnerUserId)
)
SELECT 
    tp.OwnerDisplayName, 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    tp.CommentCount,
    tp.PostCount
FROM 
    TopPosts tp
WHERE 
    tp.PostRank = 1
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
LIMIT 10;
