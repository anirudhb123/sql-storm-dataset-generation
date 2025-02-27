WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        us.DisplayName AS Author,
        COALESCE(cp.ClosedDate, 'Open') AS Status,
        COALESCE(cp.CloseReason, 'N/A') AS Reason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserStatistics us ON rp.OwnerUserId = us.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.Author,
    pd.Status,
    pd.Reason
FROM 
    PostDetails pd
WHERE 
    pd.Score > 10
    AND pd.Status = 'Open'
    AND EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = pd.PostId 
          AND v.VoteTypeId = 2 
          AND v.UserId <> (SELECT u.Id FROM Users u WHERE u.DisplayName = 'SomeSpecificUser') 
    )
ORDER BY 
    pd.Score DESC, 
    pd.ViewCount DESC
LIMIT 100;
