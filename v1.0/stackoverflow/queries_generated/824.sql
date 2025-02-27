WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.CloseCount,
    CASE 
        WHEN rp.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RankedPosts rp
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 10;

WITH MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 5
)
SELECT 
    mau.UserId,
    mau.DisplayName,
    mau.PostCount,
    mau.TotalReputation,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    MostActiveUsers mau
LEFT JOIN 
    Comments c ON mau.UserId = c.UserId
GROUP BY 
    mau.UserId, mau.DisplayName, mau.PostCount, mau.TotalReputation
HAVING 
    COUNT(DISTINCT c.Id) > 2
ORDER BY 
    mau.TotalReputation DESC
LIMIT 5;
