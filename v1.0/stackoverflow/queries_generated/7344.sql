WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostVotes AS (
    SELECT 
        p.PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CreationDate,
    tp.ViewCount,
    tp.AnswerCount,
    tp.OwnerDisplayName,
    COALESCE(pv.VoteCount, 0) AS VoteCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostVotes pv ON tp.PostId = pv.PostId
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
