WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        pht.Name = 'Post Closed'
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT 
    u.DisplayName,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    COALESCE(cp.FirstClosedDate, 'Not Closed') AS FirstClosedDate,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    tu.UserRank
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
JOIN 
    TopUsers tu ON u.Id = tu.UserId
WHERE 
    rp.rn = 1 
    AND tu.UserRank <= 10
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 20;
