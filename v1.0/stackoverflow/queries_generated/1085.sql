WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-01-01' 
        AND p.Score > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    us.UserId,
    us.DisplayName,
    us.UpVotes,
    us.DownVotes,
    phs.CloseReopenCount,
    phs.DeleteUndeleteCount
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    PostHistorySummary phs ON p.Id = phs.PostId
WHERE 
    p.rn = 1
    AND (us.UpVotes - us.DownVotes) > 10
ORDER BY 
    p.ViewCount DESC, 
    p.CreationDate DESC;
