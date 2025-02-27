WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        AVG(v.VoteTypeId = 2) AS AverageUpVotes,
        AVG(v.VoteTypeId = 3) AS AverageDownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AverageUpVotes,
        rp.AverageDownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.AverageUpVotes,
    tp.AverageDownVotes
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.PostTypeId = pt.Id
WHERE 
    pt.Name IN ('Question', 'Answer')
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
