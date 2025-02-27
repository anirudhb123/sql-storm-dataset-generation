WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RecentEditRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC) AS Rank
    FROM 
        RankedPosts rp
    WHERE 
        rp.RecentEditRank = 1
)
SELECT 
    tp.Id,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.VoteCount,
    tp.Rank
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Rank;
