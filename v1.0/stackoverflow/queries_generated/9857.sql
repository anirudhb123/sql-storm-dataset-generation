WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE((SELECT AVG(vt.Name) FROM Votes v JOIN VoteTypes vt ON v.VoteTypeId = vt.Id WHERE v.PostId = p.Id), 0) AS AverageVoteType,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) AND p.PostTypeId IN (1, 2)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.AverageVoteType,
    CAST(tp.CreationDate AS DATE) AS CreationDateOnly,
    DATEPART(HOUR, tp.CreationDate) AS CreationHour
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
