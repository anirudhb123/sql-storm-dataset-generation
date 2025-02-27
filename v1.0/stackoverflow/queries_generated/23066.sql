WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
UserSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        CASE WHEN COUNT(DISTINCT b.Id) > 0 THEN 'Has Badges' ELSE 'No Badges' END AS BadgeStatus,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.Views,
    us.BadgeStatus,
    us.TotalScore,
    us.AvgViewCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes
FROM 
    UserSummary us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
WHERE 
    (us.Reputation >= 500 AND us.Views > 1000) OR 
    (us.BadgeStatus = 'Has Badges' AND us.TotalScore > 100)  
ORDER BY 
    us.Reputation DESC,
    rp.CreationDate DESC
UNION ALL
SELECT 
    NULL AS UserId,
    'Anonymous' AS DisplayName,
    NULL AS Reputation,
    NULL AS Views,
    'No Badges' AS BadgeStatus,
    0 AS TotalScore,
    0 AS AvgViewCount,
    NULL AS PostId,
    'Low Activity Posts' AS Title,
    p.CreationDate,
    p.Score,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId 
WHERE 
    p.Score < 0 OR p.ViewCount < 50
GROUP BY 
    p.CreationDate, p.Score
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
