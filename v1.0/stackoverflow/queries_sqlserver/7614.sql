
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
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts AS p
    JOIN 
        Users AS u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -1, '2024-10-01 12:34:56')
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerDisplayName,
        bt.Name AS BadgeName,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        RankedPosts AS rp
    LEFT JOIN 
        Badges AS bt ON rp.PostId = bt.UserId 
    LEFT JOIN 
        Comments AS c ON rp.PostId = c.PostId
    WHERE 
        rp.RankScore <= 10 
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.AnswerCount, rp.CommentCount, rp.OwnerDisplayName, bt.Name
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.AnswerCount,
    fp.CommentCount,
    fp.OwnerDisplayName,
    fp.BadgeName,
    fp.TotalComments
FROM 
    FilteredPosts AS fp
WHERE 
    fp.TotalComments > 5
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;
