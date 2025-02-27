WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankPerUser,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS GlobalRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CommentCount,
        rp.RankPerUser,
        rp.GlobalRank,
        (SELECT STRING_AGG(t.TagName, ', ') 
         FROM Tags t 
         WHERE t.Id IN (SELECT UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '>'))::int[]) )) AS Tags
    FROM RankedPosts rp
    JOIN Posts p ON rp.PostId = p.Id
    WHERE rp.RankPerUser <= 3
),
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.CommentCount,
        tp.GlobalRank,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM TopPosts tp
    LEFT JOIN Votes v ON tp.PostId = v.PostId AND v.VoteTypeId IN (8, 9)  -- BountyStart and BountyClose
    GROUP BY tp.PostId, tp.Title, tp.ViewCount, tp.CommentCount, tp.GlobalRank
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.CommentCount,
    ps.GlobalRank,
    ps.TotalBounty,
    CASE 
        WHEN ps.TotalBounty > 0 THEN 'Bountied'
        ELSE 'Not Bountied'
    END AS BountyStatus
FROM PostStats ps
WHERE ps.CommentCount > 10
  AND ps.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
ORDER BY ps.GlobalRank, ps.ViewCount DESC;

