
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AnswerCount,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
        AND p.PostTypeId = 1 
),
RecentUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Location,
        u.Views,
        u.UpVotes,
        u.DownVotes
    FROM 
        Users u
    WHERE 
        u.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 6 MONTH
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        GROUP_CONCAT(DISTINCT cr.Name ORDER BY cr.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS UNSIGNED) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    cp.LastClosedDate,
    cp.CloseReasons
FROM 
    RecentUsers u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.UserPostRank <= 5
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    (u.UpVotes - u.DownVotes) > 100
    OR (cp.LastClosedDate IS NOT NULL AND cp.LastClosedDate >= '2024-10-01 12:34:56' - INTERVAL 1 MONTH)
ORDER BY 
    u.Reputation DESC, rp.ViewCount DESC;
