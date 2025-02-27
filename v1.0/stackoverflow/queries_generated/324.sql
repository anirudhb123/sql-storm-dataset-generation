WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Only Questions
    ),
CloseVoteCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseVoteCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
    ),
UserReputationInfo AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
    )
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    COALESCE(cvc.CloseVoteCount, 0) AS CloseVoteCount,
    u.Name AS OwnerName,
    u.Reputation,
    u.TotalBounties,
    u.BadgeCount,
    CASE 
        WHEN COALESCE(cvc.CloseVoteCount, 0) > 0 THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    CloseVoteCounts cvc ON rp.PostId = cvc.PostId
WHERE 
    UserPostRank = 1 -- Only the most recent post per user
ORDER BY 
    u.Reputation DESC, rp.CreationDate DESC
LIMIT 100;
