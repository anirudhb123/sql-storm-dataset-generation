WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score IS NOT NULL 
        AND p.ViewCount > 0
), 

UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (9, 10) -- BountyClose and Deletion
    WHERE 
        u.Reputation >= 1000
    GROUP BY 
        u.Id, u.Reputation
), 

TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.PostsCount,
        ur.TotalBounties,
        RANK() OVER (ORDER BY ur.Reputation DESC, ur.PostsCount DESC) AS UserRank
    FROM 
        UserRankings ur 
    WHERE 
        ur.TotalBounties IS NOT NULL
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Score AS PostScore,
    rp.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(uc.UserRank, 'Unranked') AS UserRank,
    cp.Comment AS CloseComment,
    cp.CreationDate AS CloseDate
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    TopUsers uc ON u.Id = uc.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId AND cp.CloseRank = 1 -- Latest close action if exists
WHERE 
    (rp.Rank <= 5 OR uc.UserRank IS NOT NULL) -- Top 5 posts or users with rank
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC;
