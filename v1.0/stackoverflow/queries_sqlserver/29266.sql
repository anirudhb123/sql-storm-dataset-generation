
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.PostTypeId, p.Score
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
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
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    ROUND((CAST(tp.UpVoteCount AS decimal) / NULLIF(tp.UpVoteCount + tp.DownVoteCount, 0)) * 100, 2) AS UpVotePercentage,
    STRING_AGG(DISTINCT t.TagName, ',') AS Tags
FROM 
    TopPosts tp
OUTER APPLY (
    SELECT 
        value AS TagName
    FROM 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') 
    WHERE 
        p.Id = tp.PostId
) AS t
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.CommentCount, tp.UpVoteCount, tp.DownVoteCount
ORDER BY 
    tp.ViewCount DESC, tp.CreationDate DESC;
