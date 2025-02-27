WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RN,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(case when v.VoteTypeId = 2 then 1 else 0 end), 0) AS UpVotes,
        COALESCE(SUM(case when v.VoteTypeId = 3 then 1 else 0 end), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
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
FETCH FIRST 100 ROWS ONLY;

SELECT 
    DISTINCT t.TagName
FROM 
    Tags t
WHERE 
    t.Count > (SELECT AVG(t2.Count) FROM Tags t2 WHERE t2.Count IS NOT NULL)
UNION 
SELECT 
    pt.Name AS TagName
FROM 
    PostTypes pt
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.PostTypeId = pt.Id
    )
ORDER BY 
    TagName;
