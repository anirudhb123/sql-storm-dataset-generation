WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS Upvotes, 
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS Downvotes,
        COALESCE(SUM(v.BountyAmount), 0) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Rank,
    rp.Upvotes - rp.Downvotes AS NetVotes,
    CASE
        WHEN rp.TotalBounty > 0 THEN 'Has Bounty'
        ELSE 'No Bounty'
    END AS BountyStatus,
    STUFF((
        SELECT ',' + u.DisplayName
        FROM Comments c
        JOIN Users u ON c.UserId = u.Id
        WHERE c.PostId = rp.PostId
        FOR XML PATH('')), 1, 1, '') AS Commenters,
    (SELECT COUNT(*) 
     FROM PostHistory ph 
     WHERE ph.PostId = rp.PostId 
     AND ph.PostHistoryTypeId IN (10, 11, 12, 13)) AS CloseReopenCount
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount ASC
OPTION (RECOMPILE);
