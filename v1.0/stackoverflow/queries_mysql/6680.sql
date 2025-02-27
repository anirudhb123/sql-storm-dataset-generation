
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT bh.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory bh ON p.Id = bh.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
    AND 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
), PopularPosts AS (
    SELECT 
        rp.*,
        @row_number := @row_number + 1 AS Rank
    FROM 
        RankedPosts rp,
        (SELECT @row_number := 0) AS rn
    ORDER BY 
        rp.Score DESC, rp.ViewCount DESC
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.ViewCount,
    pp.UpVotes,
    pp.DownVotes,
    pp.CommentCount,
    pp.EditCount,
    pp.Rank
FROM 
    PopularPosts pp
WHERE 
    pp.Rank <= 10  
ORDER BY 
    pp.Rank;
