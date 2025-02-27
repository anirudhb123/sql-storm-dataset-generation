
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST(DATEADD(year, -1, '2024-10-01 12:34:56') AS DATETIME)
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.Rank,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.VoteTypeId IN (8, 9)
    WHERE 
        rp.Rank <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.CreationDate, rp.Rank
)
SELECT 
    t.PostId,
    t.Title,
    t.Score,
    t.CreationDate,
    t.TotalBounty,
    u.DisplayName AS OwnerName,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = t.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = t.PostId AND v.VoteTypeId = 3) AS DownVotes
FROM 
    TopPosts t
JOIN 
    Users u ON EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = u.Id AND p.Id = t.PostId)
WHERE 
    u.Reputation > 1000
ORDER BY 
    t.Score DESC, t.TotalBounty DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
