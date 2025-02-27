WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND
        p.Score > 0
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties,
        (SELECT AVG(v2.Score)
         FROM Votes v2
         WHERE v2.UserId = u.Id) AS AvgVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostAnalysis AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        us.DisplayName,
        us.BadgeCount,
        us.TotalBounties,
        us.AvgVotes
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.PostRank = 1 AND rp.OwnerUserId = us.UserId
)
SELECT 
    pa.*,
    COALESCE(NULLIF(pa.TotalBounties, 0), 'No Bounties') AS BountyStatus,
    CASE 
        WHEN pa.BadgeCount = 0 THEN 'No Badges'
        WHEN pa.BadgeCount <= 5 THEN 'Few Badges'
        ELSE 'Many Badges'
    END AS BadgeStatus
FROM 
    PostAnalysis pa
WHERE 
    pa.ViewCount > 100
ORDER BY 
    pa.Score DESC, 
    pa.ViewCount DESC;
