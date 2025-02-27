
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RN,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST(DATEADD(day, -30, '2024-10-01') AS date)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, pt.Name
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    (rp.UpVotes - rp.DownVotes) AS NetScore,
    CASE 
        WHEN rp.RN = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRank
FROM 
    RankedPosts rp
WHERE 
    rp.Score > 0
    OR (rp.CommentCount > 5 AND rp.Score IS NULL)
ORDER BY 
    NetScore DESC,
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
