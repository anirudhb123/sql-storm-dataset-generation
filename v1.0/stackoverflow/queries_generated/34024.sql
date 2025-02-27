WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.Score > 0 AND 
        p.CreationDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END) AS LastDeletedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 12) THEN 1 END) AS CloseActionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.Score,
    rp.CreationDate AS PostCreationDate,
    rp.ViewCount,
    rp.CommentCount,
    tu.DisplayName AS UserDisplayName,
    tu.Reputation,
    phd.LastClosedDate,
    phd.LastDeletedDate,
    phd.LastReopenedDate,
    phd.CloseActionCount
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.UserRank = 1 AND rp.OwnerUserId = tu.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    phd.LastClosedDate IS NULL OR phd.LastDeletedDate IS NULL
ORDER BY 
    rp.ViewCount DESC,
    rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
