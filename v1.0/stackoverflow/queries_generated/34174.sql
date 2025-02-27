WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        pht.Name AS HistoryType,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year' -- Changes in the last year
    GROUP BY 
        ph.PostId, pht.Name
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        v.VoteTypeId = 8  -- BountyStart votes
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalBounties DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.CommentCount,
    COALESCE(phd.ChangeCount, 0) AS PostChanges,
    tu.DisplayName AS TopBountyUser,
    tu.TotalBounties
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
LEFT JOIN 
    TopUsers tu ON tu.Id = rp.OwnerUserId
WHERE 
    rp.PostRank = 1 -- Only the highest score posts per user
ORDER BY 
    rp.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
