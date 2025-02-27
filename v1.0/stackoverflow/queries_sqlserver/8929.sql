
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CAST(GETDATE() AS DATE) - 30 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.*, 
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.CreationDate DESC) AS RowNum
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 100 
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.Score, 
    tp.OwnerDisplayName, 
    tp.CreationDate, 
    tp.ViewCount, 
    tp.CommentCount, 
    tp.UpVoteCount, 
    tp.DownVoteCount
FROM 
    TopPosts tp 
ORDER BY 
    tp.RowNum 
OFFSET 10 ROWS 
FETCH NEXT 10 ROWS ONLY;
