
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        WHEN rp.Score < 0 THEN 'Negative Score'
        ELSE 'Positive Score'
    END AS ScoreCategory,
    CASE 
        WHEN rp.ViewCount < 10 THEN 'Low View Count'
        WHEN rp.ViewCount BETWEEN 10 AND 100 THEN 'Moderate View Count'
        ELSE 'High View Count'
    END AS ViewCountCategory
FROM 
    RankedPosts rp
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
