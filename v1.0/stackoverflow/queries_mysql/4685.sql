
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        GROUP_CONCAT(DISTINCT cr.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS UNSIGNED) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgesCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.DisplayName,
    us.UserId,
    rp.PostId,
    rp.Title,
    COALESCE(cp.CloseCount, 0) AS NumberOfTimesClosed,
    COALESCE(cp.CloseReasons, 'None') AS ClosedReasons,
    us.BadgesCount,
    us.UpVotesCount,
    us.DownVotesCount
FROM 
    UserStatistics us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.PostRank = 1
    AND (us.UpVotesCount - us.DownVotesCount) > 10
ORDER BY 
    us.BadgesCount DESC, 
    rp.ViewCount DESC
LIMIT 50;
