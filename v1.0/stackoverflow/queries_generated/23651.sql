WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM Posts p
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId 
    GROUP BY u.Id, u.Reputation
),

TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.BadgeCount
    FROM UserReputation ur
    WHERE ur.Reputation > 1000
),

PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        tp.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY rp.PostId ORDER BY rp.ViewCount DESC) AS ViewRank
    FROM RankedPosts rp
    LEFT JOIN PostTypes tp ON rp.PostRank = tp.Id
    WHERE rp.PostRank <= 5  -- Top 5 posts of each type
)

SELECT 
    pd.Title AS PostTitle,
    pd.CreationDate AS PostCreationDate,
    pu.DisplayName AS OwnerDisplayName,
    pu.Reputation AS OwnerReputation,
    pd.ViewCount AS TotalViews,
    COALESCE((
        SELECT AVG(v.BountyAmount) 
        FROM Votes v 
        WHERE v.PostId = pd.PostId AND v.VoteTypeId IN (8, 9)
    ), 0) AS AverageBounty,
    CASE 
        WHEN COUNT(c.Id) > 0 THEN 'Commented'
        ELSE 'No Comments'
    END AS CommentStatus
FROM PostDetails pd
INNER JOIN Users pu ON pd.PostId = pu.Id
LEFT JOIN Comments c ON pd.PostId = c.PostId
WHERE pd.ViewRank = 1
GROUP BY pd.Title, pd.CreationDate, pu.DisplayName, pu.Reputation, pd.ViewCount
ORDER BY pd.ViewCount DESC, OwnerReputation DESC
LIMIT 10;

-- Let's analyze the closing and reopening activity
WITH CloseOpenHistory AS (
    SELECT 
        ph.PostId,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS TotalCloseOpen
    FROM PostHistory ph
    GROUP BY ph.PostId
)

SELECT 
    po.Title,
    co.CloseCount,
    co.ReopenCount,
    co.TotalCloseOpen,
    CASE 
        WHEN co.CloseCount > co.ReopenCount THEN 'More Closures'
        WHEN co.ReopenCount > co.CloseCount THEN 'More Reopenings'
        ELSE 'Balanced'
    END AS ClosureStatus
FROM Posts po
INNER JOIN CloseOpenHistory co ON po.Id = co.PostId
WHERE co.TotalCloseOpen > 2  -- Posts with significant history
ORDER BY co.TotalCloseOpen DESC
LIMIT 5;
