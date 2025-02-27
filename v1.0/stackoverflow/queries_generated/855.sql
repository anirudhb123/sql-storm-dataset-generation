WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph 
        JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        SUM(COALESCE(v.Id IS NOT NULL, 0)::int) AS TotalVotes
    FROM 
        Users u
        LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    cr.CloseReasonNames,
    us.DisplayName,
    us.TotalBounties,
    us.TotalVotes
FROM 
    RankedPosts rp
    LEFT JOIN CloseReasons cr ON rp.Id = cr.PostId
    JOIN UserStats us ON rp.OwnerUserId = us.UserId
WHERE 
    rp.PostRank = 1 
    AND (us.TotalVotes > 0 OR us.TotalBounties > 0)
    AND rp.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
